//
//  GoalRoadmapLoaders.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

func loadAllGoalRoadmaps(
    onUpdate: @escaping (_ goalRoadmaps: [(Goal, Roadmap)]) -> Void
) {
    var loaded: [(Goal, Roadmap)] = []

    let fileManager = FileManager.default
    let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let goalsDir = supportDir.appendingPathComponent("Lunr/Goals")
    let roadmapsDir = supportDir.appendingPathComponent("Lunr/Roadmaps")

    guard let goalFiles = try? fileManager.contentsOfDirectory(at: goalsDir, includingPropertiesForKeys: nil) else {
        print("❌ No goals found.")
        onUpdate([])
        return
    }

    for goalFile in goalFiles {
        guard let goalData = try? Data(contentsOf: goalFile),
              let goal = try? JSONDecoder().decode(Goal.self, from: goalData) else {
            continue
        }

        let roadmapPath = roadmapsDir.appendingPathComponent("\(goal.id.uuidString).json")
        guard let roadmapData = try? Data(contentsOf: roadmapPath),
              let roadmap = try? JSONDecoder().decode(Roadmap.self, from: roadmapData) else {
            continue
        }

        loaded.append((goal, roadmap))
    }

    print("✅ Loaded \(loaded.count) roadmap-goal pairs.")
    onUpdate(loaded)
}
