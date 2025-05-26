//
//  ToolUsageRequirement.swift
//  Lunr
//
//  Created by Lwin Oo on 5/25/25.
//

import Foundation

struct ToolUsageRequirement: Codable, Identifiable {
    let id = UUID()
    let toolName: String
    let requiredHours: Int
    var loggedHours: Int = 0

    var isComplete: Bool {
        loggedHours >= requiredHours
    }

    var progressPercent: Double {
        min(Double(loggedHours) / Double(requiredHours), 1.0)
    }
}
