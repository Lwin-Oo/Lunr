//
//  FileUtils.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import AppKit
import Foundation

func openLogFile(for date: Date) {
    let formatter = DateFormatter()
    formatter.dateFormat = "M-d-yy"
    let fileURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Lunr/Screentime/\(formatter.string(from: date)).json")
    NSWorkspace.shared.activateFileViewerSelecting([fileURL])
}
