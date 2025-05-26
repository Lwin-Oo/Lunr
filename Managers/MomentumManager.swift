//
//  MomentumManager.swift
//  Lunr
//
//  Created by Lwin Oo on 5/26/25.
//

import Foundation

class MomentumManager {
    static let shared = MomentumManager()
    private let fileManager = FileManager.default
    private let directory: URL

    private init() {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directory = base.appendingPathComponent("Lunr/Momentum", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    func saveReflection(_ reflection: DailyReflection) {
        let filename = formattedFilename(from: reflection.date)
        let fileURL = directory.appendingPathComponent(filename)

        do {
            let data = try JSONEncoder().encode(reflection)
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save reflection: \(error)")
        }
    }

    func loadReflection(for date: Date) -> DailyReflection? {
        let filename = formattedFilename(from: date)
        let fileURL = directory.appendingPathComponent(filename)

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(DailyReflection.self, from: data)
    }

    private func formattedFilename(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date) + ".json"
    }
}
