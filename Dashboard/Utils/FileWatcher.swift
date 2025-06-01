//
//  FileWatcher.swift
//  Lunr
//
//  Created by Lwin Oo on 6/1/25.
//
//  This file sets up a file system watcher that monitors a specific daily log file.
//  It automatically triggers a callback when changes are detected.
//

import Foundation

// MARK: - 👁️‍🗨️ Start File Watcher

/// Sets up a file system watcher that monitors the `.json` screentime file for a specific date.
/// When the file is modified, the `onChange` callback is triggered to reload data.
///
/// - Parameters:
///   - date: The date for which the corresponding file should be watched.
///   - onChange: The closure to be called when the file is written to.
/// - Returns: A `DispatchSourceFileSystemObject` watcher, or `nil` if setup fails.
func startFileWatcher(
    for date: Date,
    onChange: @escaping () -> Void
) -> DispatchSourceFileSystemObject? {
    let fileManager = FileManager.default
    let dir = fileManager
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Lunr/Screentime")

    let formatter = DateFormatter()
    formatter.dateFormat = "M-d-yy"
    let filename = formatter.string(from: date) + ".json"
    let path = dir.appendingPathComponent(filename)

    guard fileManager.fileExists(atPath: path.path) else {
        print("❌ File does not exist: \(path.path)")
        return nil
    }

    let fileDescriptor = open(path.path, O_EVTONLY)
    guard fileDescriptor != -1 else {
        print("❌ Failed to open file descriptor.")
        return nil
    }

    let watcher = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: fileDescriptor,
        eventMask: .write,
        queue: DispatchQueue.main
    )

    watcher.setEventHandler {
        print("🔁 Detected change to \(filename). Reloading data...")
        onChange()
    }

    watcher.setCancelHandler {
        close(fileDescriptor)
    }

    watcher.resume()

    return watcher
}
