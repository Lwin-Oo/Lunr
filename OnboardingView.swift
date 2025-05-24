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

                    ProgressView(value: Double(step), total: 4)
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
                    .padding()
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)

                    Button(action: {
                        if step == 4 {
                            let newUser = User(
                                name: name,
                                milestone: milestone,
                                targetDeadline: deadline,
                                realisticEstimate: estimation,
                                createdAt: Date(),
                                lastActive: Date()
                            )
                            userManager.saveUser(newUser)
                            shouldNavigate = true
                        } else {
                            step += 1
                        }
                    }) {
                        Text(step == 4 ? "Finish" : "Next")
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
        case 2: return "2. When do you want to get it done?\n(e.g., a week, a month, 10 years)"
        case 3: return "3. When do you think you can actually finish it?"
        case 4: return "4. Finally, what's your name?"
        default: return ""
        }
    }

    private var currentBinding: Binding<String> {
        switch step {
        case 1: return $milestone
        case 2: return $deadline
        case 3: return $estimation
        case 4: return $name
        default: return .constant("")
        }
    }
}

