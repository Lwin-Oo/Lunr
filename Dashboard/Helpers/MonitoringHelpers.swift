//
//  MonitoringHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

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

