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

                        if engine.currentStep == .experienceCheck {
                            HStack(spacing: 16) {
                                Button("Yes") {
                                    userAnswer = "Yes"
                                    handleSubmit()
                                }
                                .buttonStyle(ColoredButton(color: .green))

                                Button("No") {
                                    userAnswer = "No"
                                    handleSubmit()
                                }
                                .buttonStyle(ColoredButton(color: .red))
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

                    if engine.isComplete {
                        Button("🔁 Re-run AI Evaluation") {
                            rerunExperienceEvaluation(from: engine.collectedData)
                        }
                        .padding(.top, 10)
                    }

                    Spacer()
                }
                .frame(maxWidth: 600)
                .padding(.top, 60)
                .onAppear { engine.start() }
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

            // ✅ Handle ExperienceProfile creation
            let experience: ExperienceProfile
            if let existing = ExperienceProfileManager.load(for: user.name) {
                experience = existing
            } else if d["experienceLink"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "no" {
                // User typed "No" in portfolio link step
                experience = ExperienceProfile(
                    userName: user.name,
                    experienceLevel: "Beginner",
                    skillSets: [],
                    domain: "Unknown",
                    justification: "User reported no portfolio or project link.",
                    generatedAt: now
                )
                ExperienceProfileManager.save(experience)
                print("✅ Skipped scraping. Default beginner profile saved for \(user.name)")
            } else if let link = d["experienceLink"], let desc = d["experienceDesc"] {
                // 👉 Scrape and evaluate experience
                let semaphore = DispatchSemaphore(value: 0)
                var evaluatedProfile: ExperienceProfile?

                UniversalScraper.scrape(urlString: link) { result in
                    guard let content = result else {
                        print("⚠️ Could not scrape content at \(link)")
                        semaphore.signal()
                        return
                    }

                    let prompt = """
                    You are a senior evaluator and mentor.

                    A user has submitted this project link: \(link)
                    They described it as: "\(desc)"

                    Here’s the actual content from the page:

                    📄 Title: \(content.title)
                    📄 Meta Description: \(content.description)
                    📝 Body Text Snippet:
                    \(content.bodyText)

                    Now, step by step:
                    1. What is the content about?
                    2. What domain is it in? (tech, art, music, writing, etc.)
                    3. Evaluate quality and depth
                    4. Rate skill level: Beginner / Intermediate / Advanced

                    Then summarize:
                    - Domain
                    - Skill Set / Focus Areas
                    - Experience Level
                    - Justification in one line

                    Return only your reasoning and decision log.
                    """

                    LLMClient.query(prompt: prompt) { result in
                        let domain = result.extractField(named: "Domain")
                        let skills = result.extractList(named: "Skill Set", separator: ",")
                        let level = result.extractField(named: "Experience Level")
                        let justification = result.extractField(named: "Justification")

                        evaluatedProfile = ExperienceProfile(
                            userName: user.name,
                            experienceLevel: level,
                            skillSets: skills,
                            domain: domain,
                            justification: justification,
                            generatedAt: now
                        )
                        if let p = evaluatedProfile {
                            ExperienceProfileManager.save(p)
                            print("✅ Scraped and saved experience for \(user.name)")
                        }
                        semaphore.signal()
                    }
                }

                semaphore.wait()
                experience = evaluatedProfile ?? ExperienceProfile(
                    userName: user.name,
                    experienceLevel: "Unknown",
                    skillSets: [],
                    domain: "Unknown",
                    justification: "Scraping failed.",
                    generatedAt: now
                )
            } else {
                // 👉 Fallback to unknown experience
                let saidNo = d["experienceCheck"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "no"
                experience = ExperienceProfile(
                    userName: user.name,
                    experienceLevel: saidNo ? "Beginner" : "Unknown",
                    skillSets: [],
                    domain: "Unknown",
                    justification: saidNo ? "User reported no professional experience." : "No experience data available.",
                    generatedAt: now
                )
                ExperienceProfileManager.save(experience)
            }

            // ✅ Now build roadmap
            RoadmapBuilder.buildRoadmap(for: user, goal: goal, experience: experience) { _ in
                DispatchQueue.main.async {
                    shouldNavigate = true
                }
            }
        } else {
            engine.submitAnswer(userAnswer)
            userAnswer = ""
        }
    }


    private func rerunExperienceEvaluation(from history: [String: String]) {
        guard let link = history["experienceLink"],
              let description = history["experienceDesc"],
              let userName = history["name"] else {
            print("❌ Missing required fields in history")
            return
        }

        UniversalScraper.scrape(urlString: link) { result in
            guard let content = result else {
                print("⚠️ Failed to scrape content at \(link)")
                return
            }

            let prompt = """
            You are a senior evaluator and mentor.

            A user has submitted this project link: \(link)
            They described it as: "\(description)"

            Here’s the actual content from the page:

            📄 Title: \(content.title)
            📄 Meta Description: \(content.description)
            📝 Body Text Snippet:
            \(content.bodyText)

            Now, step by step:
            1. What is the content about?
            2. What domain is it in? (tech, art, music, writing, etc.)
            3. Evaluate quality and depth
            4. Rate skill level: Beginner / Intermediate / Advanced

            Then summarize:
            - Domain
            - Skill Set / Focus Areas
            - Experience Level
            - Justification in one line

            Return only your reasoning and decision log.
            """

            LLMClient.query(prompt: prompt) { result in
                let domain = result.extractField(named: "Domain")
                let skills = result.extractList(named: "Skill Set", separator: ",")
                let level = result.extractField(named: "Experience Level")
                let justification = result.extractField(named: "Justification")

                let profile = ExperienceProfile(
                    userName: userName,
                    experienceLevel: level,
                    skillSets: skills,
                    domain: domain,
                    justification: justification,
                    generatedAt: Date()
                )

                ExperienceProfileManager.save(profile)
                print("✅ Re-saved profile for \(userName)")
            }
        }
    }
}

struct ColoredButton: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
    }
}

