//
//  SystemObserver.mm
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ApplicationServices/ApplicationServices.h>
#include <iostream>
#include <unordered_map>
#include <string>
#include <chrono>
#include <thread>
#include <iomanip>
#include <fstream>
#include <ctime>
#include <vector>
#include <mutex>
#include <atomic>
#include <numeric>
#include <filesystem>
#include <memory>
#include <regex>

#import "BridgedClassifier.h" // ✅ C bridge header (calls Swift class)

// DO NOT import "Lunr-Swift.h" — causes build issues

using Clock = std::chrono::system_clock;
using Seconds = std::chrono::seconds;

struct AppSession {
    std::string appName;
    Clock::time_point startTime;
    Seconds totalDuration = Seconds(0);
    std::vector<Seconds> focusDurations;
};

std::unordered_map<std::string, std::string> appCategory = {
    {"Xcode", "Work"},
    {"Terminal", "Work"},
    {"Visual Studio Code", "Work"},
    {"Google Chrome", "Work"},
    {"Safari", "Work"},
    {"Slack", "Work"},
    {"Discord", "Social"},
    {"Spotify", "Entertainment"},
    {"Netflix", "Entertainment"},
    {"YouTube", "Entertainment"},
    {"Twitter", "Social"},
    {"Instagram", "Social"},
    {"Messages", "Social"}
};

static std::atomic<bool> stopLogging(false);
std::mutex sessionMutex;

std::string getLunrAppSupportPath() {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* supportPath = [paths.firstObject stringByAppendingPathComponent:@"Lunr"];
    std::filesystem::create_directories([supportPath UTF8String]);
    return std::string([supportPath UTF8String]);
}

std::string extractDomainFromTitle(const std::string& title) {
    std::regex pattern("[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}");
    std::smatch match;
    if (std::regex_search(title, match, pattern)) {
        return match[0];
    }
    return title;
}

std::string getWindowTitleFromAX(pid_t pid) {
    AXUIElementRef appRef = AXUIElementCreateApplication(pid);
    AXUIElementRef windowRef = nullptr;
    CFTypeRef titleRef = nullptr;
    std::string title = "";

    if (AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute, (CFTypeRef *)&windowRef) == kAXErrorSuccess && windowRef) {
        if (AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, &titleRef) == kAXErrorSuccess && titleRef) {
            char buffer[1024];
            if (CFStringGetCString((CFStringRef)titleRef, buffer, sizeof(buffer), kCFStringEncodingUTF8)) {
                title = std::string(buffer);
            }
            CFRelease(titleRef);
        }
        CFRelease(windowRef);
    }
    CFRelease(appRef);
    return title;
}

std::string getFrontmostAppNameAndTitle() {
    if (!AXIsProcessTrusted()) {
        NSLog(@"❌ Accessibility not granted. Add the app to System Settings > Privacy & Security > Accessibility");
        return "Not Authorized";
    }

    NSRunningApplication *frontApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (!frontApp) return "Unknown";

    std::string appName = [[frontApp localizedName] UTF8String];
    pid_t pid = [frontApp processIdentifier];
    std::string title = getWindowTitleFromAX(pid);

    if (title.empty()) {
        CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
        if (!windowList) return appName;
        for (NSDictionary* entry in (__bridge NSArray*)windowList) {
            NSNumber* windowPID = entry[(id)kCGWindowOwnerPID];
            if ([windowPID intValue] == pid) {
                NSString* fallbackTitle = entry[(id)kCGWindowName];
                if (fallbackTitle && [fallbackTitle length] > 0) {
                    title = [[fallbackTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] UTF8String];
                    break;
                }
            }
        }
        CFRelease(windowList);
    }

    // Domain classification for browser
    if ((appName == "Google Chrome" || appName == "Safari") && !title.empty()) {
        std::regex pattern("[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}");
        std::smatch match;
        if (std::regex_search(title, match, pattern)) {
            title = match[0];
        }
    }

    // ✅ Call AI classifier via bridge
    const char* result = classifyContentText(title.c_str());
    std::string classification = result ? std::string(result) : "Unknown";

    NSLog(@"🧪 AX Extracted App: %s | Title: %s | 🧠 Class: %s", appName.c_str(), title.c_str(), classification.c_str());

    std::ofstream debug("/tmp/lunr_debug.log", std::ios::app);
    debug << "App: " << appName << " | Title: " << title << " | Class: " << classification << "\n";
    debug.close();

    return appName + ": " + title + " [" + classification + "]";
}

std::string getSmartAppName() {
    return getFrontmostAppNameAndTitle();
}

std::string getCurrentDateString() {
    std::time_t now = std::time(nullptr);
    char buf[11];
    std::strftime(buf, sizeof(buf), "%Y-%m-%d", std::localtime(&now));
    return std::string(buf);
}

void writeDailyLog(const std::unordered_map<std::string, AppSession>& sessions) {
    std::string path = getLunrAppSupportPath();
    std::string filename = path + "/lunr_log_" + getCurrentDateString() + ".log";
    std::ofstream file(filename);

    file << "📅 Date: " << getCurrentDateString() << "\n";
    for (const auto& [app, session] : sessions) {
        int mins = session.totalDuration.count() / 60;
        int secs = session.totalDuration.count() % 60;
        file << app << "," << mins << "m " << secs << "s\n";
    }

    file.close();
    std::cout << "\n📁 Log saved to " << filename << "\n";
}

void printSummary(const std::unordered_map<std::string, AppSession>& sessions) {
    std::ostringstream out;
    out << "\n✨ Daily App Usage Summary:\n";
    for (const auto& [app, session] : sessions) {
        int mins = session.totalDuration.count() / 60;
        int secs = session.totalDuration.count() % 60;
        out << " - " << std::setw(20) << std::left << app
            << ": " << mins << "m " << secs << "s\n";
    }

    std::string path = getLunrAppSupportPath();
    std::ofstream outFile(path + "/.lunr_behavior");
    outFile << out.str();
    outFile.close();

    std::cout << out.str();
}

void analyzeBehavior(const std::unordered_map<std::string, AppSession>& sessions) {
    std::ostringstream out;
    out << "\n🧠 [Analyzer] Behavior Snapshot:\n";

    int totalSwitches = 0;
    Seconds totalFocusTime(0);
    std::string topApp;
    int maxDuration = 0;

    std::unordered_map<std::string, int> categoryTimes;

    for (const auto& [app, session] : sessions) {
        int duration = session.totalDuration.count();
        totalFocusTime += session.totalDuration;
        totalSwitches += session.focusDurations.size();

        std::string category = appCategory.count(app) ? appCategory[app] : "Uncategorized";
        categoryTimes[category] += duration;

        if (duration > maxDuration) {
            maxDuration = duration;
            topApp = app;
        }
    }

    double avgFocus = totalSwitches
        ? totalFocusTime.count() / static_cast<double>(totalSwitches)
        : 0;

    out << " - Top App: " << topApp << " (" << maxDuration / 60 << "m " << maxDuration % 60 << "s)\n";
    out << " - Total Switches: " << totalSwitches << "\n";
    out << " - Avg. Focus Time: " << std::fixed << std::setprecision(2) << avgFocus << "s\n";
    out << " - Fragmentation Index: " << (totalSwitches > 0 ? 100.0 / totalSwitches : 0) << "\n";

    out << " - Time by Category:\n";
    for (const auto& [category, secs] : categoryTimes) {
        out << "    · " << std::setw(12) << std::left << category
            << ": " << secs / 60 << "m " << secs % 60 << "s\n";
    }

    out << "----------------------------------------\n";

    std::cout << out.str();

    std::string path = getLunrAppSupportPath();
    std::ofstream behaviorOut(path + "/.lunr_behavior");
    if (behaviorOut.is_open()) {
        behaviorOut << out.str();
        behaviorOut.close();
        std::cout << "✅ .lunr_behavior written to: " << path << "\n";
    } else {
        std::cerr << "❌ Failed to write .lunr_behavior at: " << path << "\n";
    }
}

void startBehaviorAnalyzer(std::shared_ptr<std::unordered_map<std::string, AppSession>> sharedSessions) {
    while (!stopLogging) {
        std::this_thread::sleep_for(std::chrono::seconds(30));

        std::unordered_map<std::string, AppSession> snapshot;
        {
            std::lock_guard<std::mutex> lock(sessionMutex);
            snapshot = *sharedSessions;
        }

        analyzeBehavior(snapshot);
    }
}

extern "C" void runLogger() {
    stopLogging = false;

    auto sharedSessions = std::make_shared<std::unordered_map<std::string, AppSession>>();
    std::string currentApp = getSmartAppName();
    AppSession currentSession{currentApp, Clock::now()};

    std::cout << "[Lunr] App Usage Logging Started...\n";

    std::thread analyzerThread(startBehaviorAnalyzer, sharedSessions);
    analyzerThread.detach();

    analyzeBehavior(*sharedSessions);

    int dotCounter = 0;

    while (!stopLogging) {
        std::this_thread::sleep_for(std::chrono::seconds(5));
        std::string frontApp = getSmartAppName();

        if (frontApp != currentApp) {
            auto now = Clock::now();
            Seconds duration = std::chrono::duration_cast<Seconds>(now - currentSession.startTime);

            {
                std::lock_guard<std::mutex> lock(sessionMutex);
                (*sharedSessions)[currentApp].appName = currentApp;
                (*sharedSessions)[currentApp].totalDuration += duration;
                (*sharedSessions)[currentApp].focusDurations.push_back(duration);
            }

            currentApp = frontApp;
            currentSession = AppSession{currentApp, now};
        }

        if (++dotCounter % 12 == 0) {
            std::cout << " ⏱️ " << std::flush;
        }
    }

    auto now = Clock::now();
    Seconds duration = std::chrono::duration_cast<Seconds>(now - currentSession.startTime);
    {
        std::lock_guard<std::mutex> lock(sessionMutex);
        (*sharedSessions)[currentApp].appName = currentApp;
        (*sharedSessions)[currentApp].totalDuration += duration;
        (*sharedSessions)[currentApp].focusDurations.push_back(duration);
    }

    printSummary(*sharedSessions);
    writeDailyLog(*sharedSessions);
}

extern "C" void stopLogger() {
    stopLogging = true;
    std::cout << "\n[Lunr] Stop requested.\n";
}

