//
//  FileUtils.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file contains file management utility functions, such as opening log files in Finder.
//

import AppKit
import Foundation

// MARK: - 📂 Open Log File in Finder

/// Opens the `.json` log file for a given date in the macOS Finder.
/// - Parameter date: The date corresponding to the log file to open.
func openLogFile(for date: Date) {
    let formatter = DateFormatter()
    formatter.dateFormat = "M-d-yy"
    let fileURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Lunr/Screentime/\(formatter.string(from: date)).json")
    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
}
