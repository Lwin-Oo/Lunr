//
//  DataLoaders.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

func loadData(for date: Date, onUpdate: @escaping ([DailyAppSession]) -> Void) {
    let fileManager = FileManager.default
    let dir = fileManager
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Lunr/Screentime")

    let formatter = DateFormatter()
    formatter.dateFormat = "M-d-yy"
    let filename = formatter.string(from: date) + ".json"
    let path = dir.appendingPathComponent(filename)

    print("📂 Looking for file:", path.path)

    guard fileManager.fileExists(atPath: path.path) else {
        print("❌ File not found: \(path.lastPathComponent)")
        onUpdate([])
        return
    }

    print("✅ File exists: \(path.lastPathComponent)")

    guard let data = try? Data(contentsOf: path) else {
        print("❌ Could not read data from file")
        onUpdate([])
        return
    }

    if let jsonString = String(data: data, encoding: .utf8) {
        print("🧾 Raw JSON Content:\n\(jsonString)")
    }

    guard let decoded = try? JSONDecoder().decode(DailyLog.self, from: data) else {
        print("❌ Could not decode JSON into DailyLog")
        onUpdate([])
        return
    }

    guard let sessions = decoded.sessions else {
        print("❌ 'sessions' field is nil in JSON")
        onUpdate([])
        return
    }

    print("✅ Loaded \(sessions.count) sessions from \(filename)")
    onUpdate(sessions)
}
