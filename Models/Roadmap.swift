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
    let durationDays: Int
    let toolsOrResources: [String]
    let description: String

    init(id: UUID = UUID(), title: String, durationDays: Int, toolsOrResources: [String], description: String) {
        self.id = id
        self.title = title
        self.durationDays = durationDays
        self.toolsOrResources = toolsOrResources
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case title, durationDays, toolsOrResources, description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.durationDays = try container.decode(Int.self, forKey: .durationDays)
        self.toolsOrResources = try container.decode([String].self, forKey: .toolsOrResources)
        self.description = try container.decode(String.self, forKey: .description)
    }
}
