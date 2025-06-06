//
//  OnboardingView.swift
//  Lunr
//
//  Created by Lwin Oo on 5/22/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @StateObject private var engine = OnboardingEngine()
    @State private var userAnswer = ""
    @State private var shouldNavigate = false

    var body: some View {
        if shouldNavigate || userManager.currentUser != nil {
            LunrDashboard()
        } else {
            ZStack {
                Color(NSColor.windowBackgroundColor).ignoresSafeArea()

                VStack(spacing: 28) {
                    Text("Lunr Onboarding")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if !engine.isComplete {
                        ProgressView(value: Double(engine.collectedData.count), total: 9)
                            .accentColor(.blue)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text(engine.currentQuestion)
                            .font(.title2.weight(.semibold))
                            .padding(.bottom, 8)

                        // Handle Yes/No step
                        if engine.currentStep == .experienceCheck {
                            HStack(spacing: 16) {
                                Button(action: {
                                    userAnswer = "Yes"
                                    handleSubmit()
                                }) {
                                    Text("Yes")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }

                                Button(action: {
                                    userAnswer = "No"
                                    handleSubmit()
                                }) {
                                    Text("No")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        } else {
                            TextField("Type your answer...", text: $userAnswer)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    if engine.currentStep != .experienceCheck {
                        Button(action: handleSubmit) {
                            Text(engine.isComplete ? "Finish" : "Next")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(userAnswer.isEmpty)
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .frame(maxWidth: 600)
                .padding(.top, 60)
                .onAppear {
                    engine.start()
                }
            }
        }
    }

    private func handleSubmit() {
        if engine.isComplete {
            let now = Date()
            let d = engine.collectedData

            let user = User(
                name: d["name"] ?? "Unknown",
                career: d["career"] ?? "Unknown",
                createdAt: now,
                lastActive: now
            )
            userManager.saveUser(user)

            let goal = Goal(
                id: UUID(),
                title: d["milestone"] ?? "",
                targetDeadline: d["deadline"] ?? "",
                realisticEstimate: d["estimation"] ?? "",
                dailyTime: d["dailyTime"] ?? "",
                createdAt: now
            )
            GoalManager.saveGoal(goal)

            RoadmapBuilder.buildRoadmap(for: user, goal: goal) { _ in
                DispatchQueue.main.async {
                    shouldNavigate = true
                }
            }
        } else {
            engine.submitAnswer(userAnswer)
            userAnswer = ""
        }
    }
}

