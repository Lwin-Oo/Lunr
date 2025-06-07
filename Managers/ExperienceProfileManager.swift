//
//  ExperienceProfileManager.swift
//  Lunr
//
//  Created by Lwin Oo on 6/6/25.
//

import Foundation

class ExperienceProfileManager {
    static func save(_ profile: ExperienceProfile) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/ExperienceProfiles", isDirectory: true)

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("\(profile.userName).json")

        do {
            let data = try JSONEncoder().encode(profile)
            try data.write(to: path)
            print("✅ Saved ExperienceProfile for user: \(profile.userName)")
        } catch {
            print("❌ Failed to save ExperienceProfile: \(error)")
        }
    }

    static func load(for userName: String) -> ExperienceProfile? {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/ExperienceProfiles", isDirectory: true)
        let path = dir.appendingPathComponent("\(userName).json")

        guard let data = try? Data(contentsOf: path),
              let profile = try? JSONDecoder().decode(ExperienceProfile.self, from: data) else {
            print("⚠️ ExperienceProfile not found for \(userName)")
            return nil
        }

        return profile
    }
}
