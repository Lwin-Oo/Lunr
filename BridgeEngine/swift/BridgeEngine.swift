//
//  BridgeEngine.swift
//  Lunr
//
//  Created by Lwin Oo on 6/2/25.
//

import Foundation

class BridgeEngine {
    static func createProgressionFile(from roadmap: Roadmap, stepRequirements: [UUID: [ToolUsageRequirement]]) {
        var allToolEntries: [ToolProgress] = []

        for step in roadmap.steps {
            guard let requirements = stepRequirements[step.id] else { continue }
            for req in requirements {
                allToolEntries.append(
                    ToolProgress(
                        toolName: req.toolName,
                        requiredHours: req.requiredHours,
                        progress: 0
                    )
                )
            }
        }

        let progression = RoadmapProgression(
            roadmapId: roadmap.id,
            goalId: roadmap.goalId,
            createdAt: roadmap.createdAt,
            entries: allToolEntries
        )

        saveProgression(progression)
    }

    private static func saveProgression(_ progression: RoadmapProgression) {
        let fileManager = FileManager.default
        guard let dir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Lunr/Progressions", isDirectory: true) else {
            print("❌ Could not resolve Progressions directory.")
            return
        }

        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)

        let fileURL = dir.appendingPathComponent("\(progression.roadmapId.uuidString).json")

        do {
            let data = try JSONEncoder().encode(progression)
            try data.write(to: fileURL)
            print("🪪 goalId: \(progression.goalId)")
            print("🪪 roadmapId: \(progression.roadmapId)")
            print("✅ Saved progression at: \(fileURL.path)")
        } catch {
            print("❌ Failed to save progression: \(error)")
        }
    }
}

