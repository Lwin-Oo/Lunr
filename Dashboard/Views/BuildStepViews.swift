//
//  BuildStepViews.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import SwiftUI

struct BuildStepViews: View {
    let goal: Goal
    let roadmap: Roadmap
    @Binding var expandedSteps: Set<UUID>
    let formattedDisplayDate: (Date) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let stepDates: [(step: RoadmapStep, start: Date)] = {
                var result: [(RoadmapStep, Date)] = []
                var current = roadmap.createdAt
                for step in roadmap.steps {
                    result.append((step, current))
                    current = Calendar.current.date(byAdding: .day, value: step.durationDays, to: current) ?? current
                }
                return result
            }()

            ForEach(stepDates, id: \.step.id) { (step, stepStartDate) in
                let commitmentHours = Int(goal.dailyTime) ?? 1
                let requirements = ProgressionEngine.generateRequirements(for: step, dailyCommitmentHours: commitmentHours)

                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedSteps.contains(step.id) },
                        set: { newValue in
                            if newValue {
                                expandedSteps.insert(step.id)
                            } else {
                                expandedSteps.remove(step.id)
                            }
                        }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("⏱ \(step.durationDays) days").font(.caption)
                            Text("📦 \(step.toolsOrResources.joined(separator: ", "))").font(.caption)
                            Text(step.description).font(.caption2).foregroundColor(.gray)

                            Divider().padding(.vertical, 4)
                            Text("📈 Required Tool Usage").font(.caption).bold()

                            ForEach(requirements, id: \.id) { req in
                                HStack {
                                    Text("• \(req.toolName)").font(.caption2)
                                    Spacer()
                                    Text("🎯 \(req.requiredHours) hrs").font(.caption2).foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.top, 4)
                    },
                    label: {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(formattedDisplayDate(stepStartDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 90, alignment: .leading)
                            Text("• \(step.title)").bold()
                        }
                    }
                )
            }
        }
    }
}

