//
//  ScreenMonitor.swift
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

import Foundation
import AppKit

final class MonitoringEngine {
    static let shared = MonitoringEngine()

    private var timer: Timer?
    private var currentApp: String = ""
    private var currentTitle: String = ""
    private var sessionStart: Date?
    private(set) var isRunning = false

    private init() {}

    func start() {
        guard !isRunning else { return }
        isRunning = true
        print("✅ Monitoring started.")
        sessionStart = Date()
        currentApp = getFrontmostApp()
        currentTitle = getSmartWindowTitle(for: currentApp)

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.checkActiveApp()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
        print("🔴 Monitoring stopped.")
    }

    private func checkActiveApp() {
        let newApp = getFrontmostApp()
        let newTitle = getSmartWindowTitle(for: newApp)

        if newApp != currentApp || newTitle != currentTitle {
            currentApp = newApp
            currentTitle = newTitle
            print("🕹️ Active App Changed → \(newApp): \(newTitle)")
        }
    }

    func getCurrentApp() -> String {
        currentApp
    }

    func getCurrentWindowTitle() -> String {
        currentTitle
    }

    // MARK: - Accessibility + Fallback

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

        // Try AX title first
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

        // Fallback to CGWindowList
        if let title = getFallbackWindowTitle(pid: pid) {
            return simplifyTitle(appName: appName, rawTitle: title)
        }

        return "Unnamed Window"
    }

    private func getFallbackWindowTitle(pid: pid_t) -> String? {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as NSArray? else {
            return nil
        }

        for case let entry as NSDictionary in windowList {
            if let windowPID = entry[kCGWindowOwnerPID] as? NSNumber,
               windowPID.intValue == pid,
               let windowName = entry[kCGWindowName] as? String,
               !windowName.trimmingCharacters(in: .whitespaces).isEmpty {
                return windowName
            }
        }

        return nil
    }

    private func simplifyTitle(appName: String, rawTitle: String) -> String {
        // Chrome/Safari: extract domain if it's a URL-like title
        if ["Google Chrome", "Safari"].contains(appName) {
            if let match = rawTitle.range(of: #"[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}"#, options: .regularExpression) {
                return String(rawTitle[match])
            }
        }

        return rawTitle
    }
}
