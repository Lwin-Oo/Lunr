//
//  GoalRoadmapLoaders.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file loads all saved Goal-Roadmap pairs from disk by matching goal files with their corresponding roadmap files.
//  It decodes the goal and roadmap JSON files and returns them in tuples for rendering and planning.
//

import Foundation

// MARK: - 📦 Load All Goal + Roadmap Pairs

/// Loads all saved `Goal` and `Roadmap` pairs from disk.
/// Each roadmap is matched to its goal via the goal's UUID.
///
/// - Parameter onUpdate: A closure that receives the list of matched `(Goal, Roadmap)` pairs.
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
