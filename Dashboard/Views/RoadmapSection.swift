//
//  RoadmapSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This view handles the display of the goal roadmaps, including each step's details, progress indication, and associated tool usage requirements. It also shows a side panel with a daily encouragement message if available.

import SwiftUI

// MARK: - 🗺️ RoadmapSection
struct RoadmapSection: View {
    @Binding var goalRoadmaps: [(Goal, Roadmap)]
    @Binding var expandedStepsByGoal: [UUID: Set<UUID>]
    @Binding var stepRequirements: [UUID: [ToolUsageRequirement]]
    @Binding var todayReflection: DailyReflection?
    let encouragementText: String
    let currentRoadmapStepIndex: (Roadmap) -> Int?
    let formattedDisplayDate: (Date) -> String

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // Left: Roadmap list
            VStack(alignment: .leading, spacing: 12) {
                if goalRoadmaps.isEmpty {
                    Text("LLM is still generating your roadmap...")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ForEach(goalRoadmaps, id: \.0.id) { goal, roadmap in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🎯 Goal: \(goal.title)").font(.subheadline).foregroundColor(.gray)
                            Text("📅 Roadmap").font(.headline)

                            let stepDates: [(RoadmapStep, Date)] = {
                                var dates: [(RoadmapStep, Date)] = []
                                var current = roadmap.createdAt
                                for step in roadmap.steps {
                                    dates.append((step, current))
                                    current = Calendar.current.date(byAdding: .day, value: Int(step.durationDays), to: current) ?? current
                                }
                                return dates
                            }()

                            let currentIndex = currentRoadmapStepIndex(roadmap)

                            ForEach(Array(stepDates.enumerated()), id: \.element.0.id) { index, pair in
                                let step = pair.0
                                let date = pair.1
                                let commitment = Int(goal.dailyTime) ?? 1

                                let requirements = stepRequirements[step.id] ?? {
                                    let generated = ProgressionEngine.generateRequirements(for: step, dailyCommitmentHours: commitment)
                                    stepRequirements[step.id] = generated
                                    return generated
                                }()

                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: {
                                            expandedStepsByGoal[goal.id, default: []].contains(step.id)
                                        },
                                        set: { newValue in
                                            if newValue {
                                                expandedStepsByGoal[goal.id, default: []].insert(step.id)
                                            } else {
                                                expandedStepsByGoal[goal.id, default: []].remove(step.id)
                                            }
                                        }
                                    ),
                                    content: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("⏱ \(formatDurationDays(step.durationDays))").font(.caption)
                                            Text("📦 \(step.toolsOrResources.joined(separator: ", "))").font(.caption)
                                            Text(step.description).font(.caption2).foregroundColor(.gray)

                                            Divider().padding(.vertical, 4)
                                            Text("📈 Required Tool Usage").font(.caption).bold()

                                            let toolProgressList = ProgressionManager.loadProgression(for: roadmap.id)

                                            ForEach(requirements, id: \.id) { req in
                                                let progress = toolProgressList.first { $0.toolName == req.toolName }?.progress ?? 0
                                                let percent = min(progress / (req.requiredHours * 3600), 1.0)


                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text("• \(req.toolName)").font(.caption2)
                                                        Spacer()
                                                        
                                                        Text("\(formatSecondsToReadable(progress)) / \(formatHoursMinutes(req.requiredHours))")
                            
                                                            .font(.caption2)
                                                            .foregroundColor(.gray)
                                                    }

                                                    ProgressView(value: percent)
                                                        .frame(height: 4)
                                                        .accentColor(.blue)
                                                }
                                            }

                                        }
                                        .padding(.top, 4)
                                    },
                                    label: {
                                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                                            Text(formattedDisplayDate(date))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .frame(width: 90, alignment: .leading)
                                            Text("• \(step.title)").bold()

                                            if index == currentIndex {
                                                Text("📍 You are here")
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

            // Right: Encouragement
            if let reflection = todayReflection {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💬 Daily Encouragement").font(.headline)
                    Text(encouragementText)
                        .font(.caption)
                        .padding(10)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
                .frame(width: 240)
            }
        }
    }
}
