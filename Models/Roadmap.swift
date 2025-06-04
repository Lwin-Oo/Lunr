//
//  Roadmap.swift
//  Lunr
//
//  Created by Lwin Oo on 5/24/25.
//

import Foundation

struct Roadmap: Codable, Identifiable {
    let id: UUID
    let goalId: UUID
    let createdAt: Date
    let steps: [RoadmapStep]
}

struct RoadmapStep: Codable, Identifiable {
    let id: UUID
    let title: String
    let durationDays: Double
    let toolsOrResources: [String]
    let description: String

    init(id: UUID = UUID(), title: String, durationDays: Double, toolsOrResources: [String], description: String) {
        self.id = id
        self.title = title
        self.durationDays = durationDays
        self.toolsOrResources = toolsOrResources
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case durationDays
        case toolsOrResources
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.durationDays = try container.decode(Double.self, forKey: .durationDays)
        self.toolsOrResources = try container.decode([String].self, forKey: .toolsOrResources)
        self.description = try container.decode(String.self, forKey: .description)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(durationDays, forKey: .durationDays)
        try container.encode(toolsOrResources, forKey: .toolsOrResources)
        try container.encode(description, forKey: .description)
    }
}
