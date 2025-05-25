//
//  ScreenMonitor.swift
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

import Foundation
import AppKit

private let systemPrompt = """
You are an AI assistant that classifies computer app usage based on how productive it is. Given the name of an application and the current window/tab title, return one of the following categories:

- Productive
- Entertainment
- Communication
- Utility
- Design
- Code
- Social
- Educational
- Gaming
- Uncategorized

Reply ONLY with the category.
"""

@_silgen_name("classifyContentText")
func classifyContentText(_ input: UnsafePointer<CChar>) -> UnsafePointer<CChar>?

final class MonitoringEngine {
    static let shared = MonitoringEngine()

    private var timer: Timer?
    private var currentApp: String = ""
    private var currentTitle: String = ""
    private var sessionStart: Date?
    private var sessions: [DailyAppSession] = []

    private(set) var isRunning = false

    private init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true
        print("✅ Monitoring started.")

        currentApp = getFrontmostApp()
        currentTitle = getSmartWindowTitle(for: currentApp)
        sessionStart = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.monitorTick()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        endCurrentSession()

        print("📦 Final Sessions Before Save:")
        for s in sessions {
            print("🧾 App title: \(s.app), Tab: \(s.windowTitle), Category: \(s.classification)")
        }

        let log = DailyLog(date: formattedToday(), sessions: sessions)

        if let encoded = try? JSONEncoder().encode(log),
           let jsonStr = String(data: encoded, encoding: .utf8) {
            print("📝 Full JSON Dump:\n\(jsonStr)")
        }

        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let savedPath = dir.appendingPathComponent("\(log.date).json")
        try? JSONEncoder().encode(log).write(to: savedPath)

        print("✅ Saved to: \(savedPath.path)")
        sessions.removeAll()
        print("🔴 Monitoring stopped.")
    }

    private func monitorTick() {
        let newApp = getFrontmostApp()
        let newTitle = getSmartWindowTitle(for: newApp)

        if newApp != currentApp || newTitle != currentTitle {
            endCurrentSession() // stores previous one

            currentApp = newApp
            currentTitle = newTitle
            sessionStart = Date()

            print("🕹️ Active App Changed → \(newApp): \(newTitle)")
            print("🧠 AI categorizing...")

            let fullPrompt = """
            \(systemPrompt)

            App: \(newApp)
            Tab Title: \(newTitle)

            Category:
            """

            queryLLM(prompt: fullPrompt) { category in
                DispatchQueue.main.async {
                    print("🧠 App title: \(newApp), Tab: \(newTitle), Category: \(category)")

                    // Add new LLM-classified session
                    let session = DailyAppSession(
                        app: newApp,
                        windowTitle: newTitle,
                        startTime: self.iso8601(self.sessionStart ?? Date()),
                        endTime: self.iso8601(Date()),
                        durationSeconds: Int(Date().timeIntervalSince(self.sessionStart ?? Date())),
                        classification: category
                    )

                    self.sessions.append(session)
                    self.sessionStart = Date()
                }
            }
        }

        print("🟢 Logger tick - recording app usage...")
    }


    private func endCurrentSession() {
        guard let start = sessionStart else { return }
        let duration = Int(Date().timeIntervalSince(start))
        if duration < 3 { return }

        let prompt = """
        \(systemPrompt)

        App: \(currentApp)
        Tab Title: \(currentTitle)

        Category:
        """

        queryLLM(prompt: prompt) { category in
            DispatchQueue.main.async {
                let session = DailyAppSession(
                    app: self.currentApp,
                    windowTitle: self.currentTitle,
                    startTime: self.iso8601(start),
                    endTime: self.iso8601(Date()),
                    durationSeconds: duration,
                    classification: category
                )
                self.sessions.append(session)
            }
        }
    }



//    private func classify(title: String) -> String {
//        guard let cstr = title.cString(using: .utf8) else { return "Uncategorized" }
//        guard let result = classifyContentText(cstr) else { return "Uncategorized" }
//        return String(cString: result)
//    }

    private func getFrontmostApp() -> String {
        NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
    }

    private func getSmartWindowTitle(for appName: String) -> String {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let pid = app.processIdentifier as pid_t?
        else {
            return "Unknown"
        }

        let trusted = AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary)
        guard trusted else {
            return "🔒 Permission Needed"
        }

        let appRef = AXUIElementCreateApplication(pid)
        var window: CFTypeRef?
        if AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &window) == .success,
           let window = window {
            var title: CFTypeRef?
            if AXUIElementCopyAttributeValue(window as! AXUIElement, kAXTitleAttribute as CFString, &title) == .success,
               let titleStr = title as? String, !titleStr.isEmpty {
                return simplifyTitle(appName: appName, rawTitle: titleStr)
            }
        }

        if let fallback = getFallbackWindowTitle(pid: pid) {
            return simplifyTitle(appName: appName, rawTitle: fallback)
        }

        return "Unnamed Window"
    }

    private func getFallbackWindowTitle(pid: pid_t) -> String? {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for entry in windowList {
            if let ownerPID = entry[kCGWindowOwnerPID as String] as? Int,
               ownerPID == pid,
               let title = entry[kCGWindowName as String] as? String,
               !title.trimmingCharacters(in: .whitespaces).isEmpty {
                return title
            }
        }

        return nil
    }

    private func simplifyTitle(appName: String, rawTitle: String) -> String {
        if ["Google Chrome", "Safari"].contains(appName) {
            if let match = rawTitle.range(of: #"[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}"#, options: .regularExpression) {
                return String(rawTitle[match])
            }
        }
        return rawTitle
    }

    private func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func queryLLM(prompt: String, completion: @escaping (String) -> Void) {
        let url = URL(string: "http://localhost:11434/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let json: [String: Any] = [
            "model": "mistral",
            "prompt": prompt,
            "stream": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(OllamaResponse.self, from: data)
            else {
                completion("Unknown")
                return
            }
            completion(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}
