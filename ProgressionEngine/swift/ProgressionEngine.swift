//
//  ProgressionEngine.swift
//  Lunr
//
//  Created by Lwin Oo on 5/25/25.
//

import Foundation

class ProgressionEngine {
    static func generateRequirements(for step: RoadmapStep, dailyCommitmentHours: Int) -> [ToolUsageRequirement] {
        let totalAvailableHours = step.durationDays * 24
        let perToolHours = totalAvailableHours / max(Double(step.toolsOrResources.count), 1)

        return step.toolsOrResources.map {
            ToolUsageRequirement(toolName: $0, requiredHours: perToolHours)
        }
    }

    static func updateProgress(_ requirements: inout [ToolUsageRequirement], toolName: String, additionalHours: Int) {
        guard let index = requirements.firstIndex(where: { $0.toolName == toolName }) else { return }
        requirements[index].loggedHours += additionalHours
    }
}

