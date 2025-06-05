//
//  ProgressionManager.swift
//  Lunr
//
//  Created by Lwin Oo on 6/2/25.
//

import Foundation

class ProgressionManager {
    static func loadProgression(for roadmapId: UUID) -> [ToolProgress] {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Progressions")

        let path = dir.appendingPathComponent("\(roadmapId.uuidString).json")

        guard FileManager.default.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path),
              let progression = try? JSONDecoder().decode(RoadmapProgression.self, from: data)
        else {
            print("⚠️ No saved progression found for roadmap \(roadmapId)")
            return []
        }

        // ✅ Inject loaded progression into ToolProgressTracker
        ToolProgressTracker.shared.configure(with: progression)

        return progression.entries
    }
}

