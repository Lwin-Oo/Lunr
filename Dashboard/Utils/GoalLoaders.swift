//
//  GoalLoaders.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

func loadGoal(for user: User) -> Goal? {
    let goalsDir = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Lunr/Goals")

    guard let files = try? FileManager.default.contentsOfDirectory(at: goalsDir, includingPropertiesForKeys: nil) else {
        return nil
    }

    for file in files.reversed() {
        if let data = try? Data(contentsOf: file),
           let goal = try? JSONDecoder().decode(Goal.self, from: data) {
            return goal
        }
    }

    return nil
}
