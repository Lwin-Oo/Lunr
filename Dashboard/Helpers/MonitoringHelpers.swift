//
//  MonitoringHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file provides helper logic to toggle the monitoring state of the app,
//  controlling both the logger and the MonitoringEngine.
//

import Foundation

// MARK: - 🔁 Monitoring Toggle Handler

/// Toggles the monitoring state by starting or stopping the logger and engine.
///
/// - Parameters:
///   - isMonitoring: A boolean flag tracking whether monitoring is currently active.
///   - runLogger: Closure to execute when starting monitoring.
///   - stopLogger: Closure to execute when stopping monitoring.
func handleMonitoringToggle(
    isMonitoring: inout Bool,
    runLogger: () -> Void,
    stopLogger: () -> Void
) {
    if isMonitoring {
        stopLogger()
        MonitoringEngine.shared.stop()
    } else {
        runLogger()
        MonitoringEngine.shared.start()
    }
    isMonitoring = MonitoringEngine.shared.isRunning
}

