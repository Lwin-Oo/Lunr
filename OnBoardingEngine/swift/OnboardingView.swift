//
//  OnboardingView.swift
//  Lunr
//
//  Created by Lwin Oo on 5/22/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager

    @State private var step = 1
    @State private var milestone = ""
    @State private var deadline = ""
    @State private var estimation = ""
    @State private var dailyTime = ""
    @State private var career = ""
    @State private var name = ""
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

                    ProgressView(value: Double(step), total: 6)
                        .accentColor(.blue)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 16) {
                        Text(questionTitle)
                            .font(.title2.weight(.semibold))
                            .padding(.bottom, 8)

                        TextField("Type your answer...", text: currentBinding)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Button(action: handleStep) {
                        Text(step == 6 ? "Finish" : "Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .frame(maxWidth: 600)
                .padding(.top, 60)
            }
        }
    }

    private var questionTitle: String {
        switch step {
        case 1: return "1. What milestone do you want to achieve?"
        case 2: return "2. When do you want to get it done?"
        case 3: return "3. When do you think you can realistically finish it?"
        case 4: return "4. How much time can you commit daily?"
        case 5: return "5. What do you currently do?"
        case 6: return "6. Finally, what's your name?"
        default: return ""
        }
    }

    private var currentBinding: Binding<String> {
        switch step {
        case 1: return $milestone
        case 2: return $deadline
        case 3: return $estimation
        case 4: return $dailyTime
        case 5: return $career
        case 6: return $name
        default: return .constant("")
        }
    }

    private func handleStep() {
        if step == 6 {
            let now = Date()

            let user = User(
                name: name,
                career: career,
                createdAt: now,
                lastActive: now
            )
            userManager.saveUser(user)

            let goal = Goal(
                id: UUID(),
                title: milestone,
                targetDeadline: deadline,
                realisticEstimate: estimation,
                dailyTime: dailyTime,
                createdAt: now
            )
            
            UserManager.shared.saveUser(user)
            GoalManager.saveGoal(goal)

            RoadmapBuilder.buildRoadmap(for: user, goal: goal) { steps in
                let roadmap = Roadmap(
                    id: UUID(),
                    goalId: goal.id,
                    createdAt: Date(),
                    steps: steps
                )
                RoadmapManager.saveRoadmap(roadmap)
                DispatchQueue.main.async {
                    shouldNavigate = true
                }
            }

        } else {
            step += 1
        }
    }
}
