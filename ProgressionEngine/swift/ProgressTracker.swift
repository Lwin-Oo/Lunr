//
//  ProgressTracker.swift
//  Lunr
//
//  Created by Lwin Oo on 5/25/25.
//

import Foundation

class ProgressTracker: ObservableObject {
    @Published var toolRequirements: [ToolUsageRequirement] = []

    func load(for step: RoadmapStep, commitmentHours: Int) {
        toolRequirements = ProgressionEngine.generateRequirements(for: step, dailyCommitmentHours: commitmentHours)
    }

    func logTime(for tool: String, hours: Int) {
        ProgressionEngine.updateProgress(&toolRequirements, toolName: tool, additionalHours: hours)
    }

    func stepCompletionPercentage() -> Double {
        guard !toolRequirements.isEmpty else { return 0.0 }
        let total = toolRequirements.map { $0.progressPercent }.reduce(0, +)
        return total / Double(toolRequirements.count)
    }

    func isStepComplete() -> Bool {
        toolRequirements.allSatisfy { $0.isComplete }
    }
}
