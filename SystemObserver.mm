//
//  SystemObserver.mm
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
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
    {"Messages", "Social"},
    {"Chrome: youtube.com", "Entertainment"},
    {"Chrome: twitter.com", "Social"},
    {"Chrome: netflix.com", "Entertainment"},
    {"Chrome: slack.com", "Work"},
    {"Chrome: github.com", "Work"},
    {"Chrome: reddit.com", "Entertainment"},
    {"Chrome: linkedin.com", "Work"}
};

static std::atomic<bool> stopLogging(false);
std::mutex sessionMutex;

std::string getLunrAppSupportPath() {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString* supportPath = [paths.firstObject stringByAppendingPathComponent:@"Lunr"];
    std::filesystem::create_directories([supportPath UTF8String]);
    return std::string([supportPath UTF8String]);
}

std::string getFrontmostApp() {
    NSRunningApplication* frontmost = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSString* name = [frontmost localizedName];
    return std::string([name UTF8String]);
}

std::string getChromeDomain() {
    __block std::string domain = "unknown";

    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.google.Chrome"] count] == 0) {
        std::cerr << "🚫 Chrome is not running.\n";
        return "unknown";
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        NSString *scriptSource = @"\
            tell application \"Google Chrome\"\n\
                set theTab to active tab of front window\n\
                return URL of theTab\n\
            end tell";

        NSAppleScript *script = [[NSAppleScript alloc] initWithSource:scriptSource];
        NSDictionary *errorDict = nil;
        NSAppleEventDescriptor *result = [script executeAndReturnError:&errorDict];

        if (!result) {
            std::cerr << "🚫 AppleScript Error: " << [[errorDict description] UTF8String] << "\n";
            return;
        }

        NSString *urlString = [result stringValue];
        NSURL *url = [NSURL URLWithString:urlString];
        if (!url || !url.host) {
            std::cerr << "❌ Failed to parse Chrome tab URL\n";
            return;
        }

        domain = std::string([[url.host lowercaseString] UTF8String]);
    });

    return domain;
}

std::string getSmartAppName() {
    std::string app = getFrontmostApp();
    if (app == "Google Chrome") {
        std::string domain = getChromeDomain();
        if (domain != "unknown") {
            return "Chrome: " + domain;
        }
    }
    return app;
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

    // 🚨 Prompt Automation access
    dispatch_sync(dispatch_get_main_queue(), ^{
        // Wait for Chrome to fully launch (max 5 seconds)
        int retries = 10;
        while (retries-- > 0) {
            NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.google.Chrome"];
            if (runningApps.count > 0) break;
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
        }

        NSArray *runningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.google.Chrome"];
        if (runningApps.count == 0) {
            NSLog(@"🚫 Chrome did not launch in time. Skipping AppleScript.");
            return;
        }

        NSString *script = @"\
            tell application \"Google Chrome\"\n\
                if (count of windows) > 0 then\n\
                    set theTab to active tab of front window\n\
                    set theURL to URL of theTab\n\
                end if\n\
            end tell";

        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
        NSDictionary *err = nil;
        [appleScript executeAndReturnError:&err];

        if (err) {
            NSLog(@"🚫 Automation error: %@", err);
        } else {
            NSLog(@"✅ Chrome Automation succeeded");
        }
    });


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

