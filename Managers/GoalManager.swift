//
//  GoalManager.swift
//  Lunr
//
//  Created by Lwin Oo on 5/24/25.
//

import Foundation

class GoalManager {
    static func saveGoal(_ goal: Goal) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Goals", isDirectory: true)

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("\(goal.id.uuidString).json")

        print("📦 Saving GOAL to: \(path.path)")
        if let data = try? JSONEncoder().encode(goal) {
            do {
                try data.write(to: path)
                print("✅ Goal saved successfully.\n")
            } catch {
                print("❌ Failed to save goal: \(error)")
            }
        } else {
            print("❌ Failed to encode goal.")
        }
    }
}

