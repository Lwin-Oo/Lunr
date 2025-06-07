//
//  OnboardingEngine.swift
//  Lunr
//
//  Created by Lwin Oo on 6/4/25.
//

import Foundation

final class OnboardingEngine: ObservableObject {
    @Published var currentQuestion: String = ""
    @Published var currentStep: OnboardingStep = .milestone
    @Published var history: [String: String] = [:]
    @Published var isComplete: Bool = false

    func start() {
        advanceToNextPrompt()
    }

    func submitAnswer(_ answer: String) {
        history[currentStep.rawValue] = answer

        // Delay AI trigger until both link and name are available
        if currentStep == .experienceLink, let name = history["name"] {
            let link = answer
            let desc = history["experienceDesc"] ?? ""
            evaluateUserExperience(userName: name, link: link, description: desc)
        }

        advanceStep()
        advanceToNextPrompt()
    }

    private func advanceStep() {
        switch currentStep {
        case .milestone:
            currentStep = .experienceCheck
        case .experienceCheck:
            if let answer = history["experienceCheck"], answer.lowercased() == "yes" {
                currentStep = .experienceDesc
            } else {
                currentStep = .success
            }
        case .experienceDesc:
            currentStep = .experienceLink
        case .experienceLink:
            currentStep = .success
        case .success:
            currentStep = .deadline
        case .deadline:
            currentStep = .estimation
        case .estimation:
            currentStep = .dailyTime
        case .dailyTime:
            currentStep = .career
        case .career:
            currentStep = .name
        case .name:
            isComplete = true
        }
    }

    private func advanceToNextPrompt() {
        guard !isComplete else { return }

        let question = aiPrompt(for: currentStep.rawValue, history: history)
        DispatchQueue.main.async {
            self.currentQuestion = question
        }
    }

    // MARK: - 🧠 Prompt Generator
    private func aiPrompt(for step: String, history: [String: String]) -> String {
        switch step {
        case "milestone":
            return "What do you want to achieve? Be specific and concise."
        case "experienceCheck":
            if let goal = history["milestone"] {
                return "Do you have any experience with \(goal)?"
            } else {
                return "Do you have any experience related to your goal?"
            }
        case "experienceDesc":
            return "Briefly describe your experience in one sentence."
        case "experienceLink":
            return "Paste a link if you have a portfolio, repo, or related project (or type 'No')."
        case "success":
            let goal = history["milestone"] ?? "your goal"
            return "How will you know you've succeeded in achieving \(goal)? Define success in your own words."
        case "deadline":
            return "What's your ideal deadline to finish this?"
        case "estimation":
            return "Realistically, how long do you think it will take to complete it?"
        case "dailyTime":
            return "How much time can you commit each day toward this?"
        case "career":
            return "What do you currently do (job, student, etc.)?"
        case "name":
            return "Finally, what's your name?"
        default:
            return "What's your answer?"
        }
    }

    // MARK: - 🌐 Experience Evaluation Logic
    func evaluateUserExperience(userName: String, link: String, description: String) {
        if link.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "no" {
            let profile = ExperienceProfile(
                userName: userName,
                experienceLevel: "Beginner",
                skillSets: [],
                domain: "Unknown",
                justification: "User reported no portfolio or project link.",
                generatedAt: Date()
            )
            ExperienceProfileManager.save(profile)
            print("✅ Skipped scraping. Default beginner profile saved for \(userName)")
            return
        }

        UniversalScraper.scrape(urlString: link) { result in
            guard let content = result else {
                print("⚠️ Could not scrape content at \(link)")
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
                print("✅ ExperienceProfile saved for \(userName)")
            }
        }
    }

    // MARK: - 📦 Collected Data Accessor
    var collectedData: [String: String] {
        return history
    }
}
