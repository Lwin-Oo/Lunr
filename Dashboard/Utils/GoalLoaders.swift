//
//  GoalLoaders.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file handles loading the most recent saved goal data for a given user from disk.
//  It decodes the latest `.json` file found in the Goals directory.
//

import Foundation

// MARK: - 🎯 Load Goal for User

/// Loads the most recent saved `Goal` for the given user by scanning the `Lunr/Goals` directory.
/// It returns the latest goal file found (by file order).
///
/// - Parameter user: The current user.
/// - Returns: The most recently saved `Goal` if available, or `nil` if none found.
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
