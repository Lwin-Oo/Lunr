//
//  SystemObserver.mm
//  Lunr
//
//  Created by Lwin Oo on 5/18/25.
//

#import <AppKit/AppKit.h>
#include <iostream>
#include <unordered_map>
#include <string>
#include <chrono>
#include <thread>
#include <iomanip>
#include <fstream>
#include <ctime>
#include <atomic> // For stop flag

// 🔧 Clock and Duration aliases
using Clock = std::chrono::system_clock;
using Seconds = std::chrono::seconds;

// 🧠 App session tracker
struct AppSession {
    std::string appName;
    Clock::time_point startTime;
    Seconds totalDuration = Seconds(0);
};

// 🔁 Stop flag shared across threads
static std::atomic<bool> stopLogging(false); // ✅ NEW

// 🍎 Get frontmost app name
std::string getFrontmostApp() {
    NSRunningApplication* frontmost = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSString* name = [frontmost localizedName];
    return std::string([name UTF8String]);
}

// 🗓️ Today's date string
std::string getCurrentDateString() {
    std::time_t now = std::time(nullptr);
    char buf[11];
    std::strftime(buf, sizeof(buf), "%Y-%m-%d", std::localtime(&now));
    return std::string(buf);
}

// 💾 Write log file
void writeDailyLog(const std::unordered_map<std::string, AppSession>& sessions) {
    std::string filename = "lunr_log_" + getCurrentDateString() + ".log";
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

// 📺 Terminal summary
void printSummary(const std::unordered_map<std::string, AppSession>& sessions) {
    std::cout << "\n✨ Daily App Usage Summary:\n";
    for (const auto& [app, session] : sessions) {
        int mins = session.totalDuration.count() / 60;
        int secs = session.totalDuration.count() % 60;
        std::cout << " - " << std::setw(20) << std::left << app
                  << ": " << mins << "m " << secs << "s\n";
    }
}

// 🔁 Start logging
extern "C" void runLogger() {
    stopLogging = false; // ✅ Reset stop flag

    std::unordered_map<std::string, AppSession> sessions;
    std::string currentApp = getFrontmostApp();
    AppSession currentSession{currentApp, Clock::now()};

    std::cout << "[Lunr] App Usage Logging Started...\n";

    while (!stopLogging) { // ✅ Controlled loop
        std::this_thread::sleep_for(std::chrono::seconds(5));
        std::string frontApp = getFrontmostApp();

        if (frontApp != currentApp) {
            auto now = Clock::now();
            Seconds duration = std::chrono::duration_cast<Seconds>(now - currentSession.startTime);
            sessions[currentApp].appName = currentApp;
            sessions[currentApp].totalDuration += duration;

            currentApp = frontApp;
            currentSession = AppSession{currentApp, now};
        }

        std::cout << "." << std::flush;
    }

    // Final session cleanup
    auto now = Clock::now();
    Seconds duration = std::chrono::duration_cast<Seconds>(now - currentSession.startTime);
    sessions[currentApp].appName = currentApp;
    sessions[currentApp].totalDuration += duration;

    printSummary(sessions);
    writeDailyLog(sessions);
}

// 🛑 Stop logging from Swift
extern "C" void stopLogger() {
    stopLogging = true;
    std::cout << "\n[Lunr] Stop requested.\n";
}

