//
//  RoadmapManager.swift
//  Lunr
//
//  Created by Lwin Oo on 5/24/25.
//

import Foundation

class RoadmapManager {
    static func saveRoadmap(_ roadmap: Roadmap) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Roadmaps", isDirectory: true)

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("\(roadmap.goalId.uuidString).json")

        print("📦 Preparing to save ROADMAP")
        print("🧭 goalId: \(roadmap.goalId.uuidString)")
        print("🧭 roadmapId: \(roadmap.id.uuidString)")
        print("📂 Target path: \(path.path)")

        if let data = try? JSONEncoder().encode(roadmap) {
            do {
                try data.write(to: path)
                print("✅ Roadmap saved successfully at \(path.lastPathComponent)\n")
            } catch {
                print("❌ Failed to save roadmap: \(error)")
            }
        } else {
            print("❌ Failed to encode roadmap.")
        }
    }

}

