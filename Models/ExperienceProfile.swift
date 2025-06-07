//
//  ExperienceProfile.swift
//  Lunr
//
//  Created by Lwin Oo on 6/6/25.
//

import Foundation

struct ExperienceProfile: Codable {
    let userName: String           // 🔗 Reference to User.name
    let experienceLevel: String    // "Beginner", "Intermediate", "Advanced"
    let skillSets: [String]        // ["Swift", "Web Dev", ...]
    let domain: String             // "Tech", "Art", "Writing", etc.
    let justification: String      // Summary reasoning
    let generatedAt: Date
}
