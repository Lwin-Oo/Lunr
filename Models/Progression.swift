//
//  Progression.swift
//  Lunr
//
//  Created by Lwin Oo on 6/2/25.
//

import Foundation

struct ToolProgress: Codable {
    let toolName: String
    let requiredHours: Double
    var progress: TimeInterval = 0  // in seconds
}

struct RoadmapProgression: Codable {
    let roadmapId: UUID
    let goalId: UUID
    let createdAt: Date
    let entries: [ToolProgress]
}
