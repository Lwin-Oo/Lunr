//
//  RoadmapBuilder.swift
//  Lunr
//
//  Created by Lwin Oo on 5/24/25.
//

import Foundation

class RoadmapBuilder {
    static func buildRoadmap(for user: User, goal: Goal, experience: ExperienceProfile?, completion: @escaping ([RoadmapStep]) -> Void) {
        let systemPrompt = """
        You are a productivity roadmap builder AI. Your task is to generate a JSON array of roadmap steps personalized to a user’s goal and their actual verified experience.

        Rules:
        - Use the user’s skill set to skip beginner/fundamental steps if they already know those skills.
        - If the user is a beginner, slow down the roadmap and include key learning steps.
        - If the user has experience and their goal timeline is aggressive but possible, allow it.
        - If the user has **no experience** and their goal is unrealistic (e.g. writing a book in 10 days), adjust the roadmap and include a note at the beginning.

        For each roadmap step, include:
        - title (string)
        - durationDays (decimal, like 0.5 for 12 hrs)
        - toolsOrResources (array of concrete tools/platforms, avoid vague entries like “internet”)
        - description (1-2 sentence summary)

        Respond ONLY with a valid JSON array. No explanations or extra comments.
        """

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let now = Date()
        let deadlineDate = parseDeadline(from: goal.targetDeadline, now: now)
        let daysUntilDeadline = max(Calendar.current.dateComponents([.day], from: now, to: deadlineDate).day ?? 1, 1)

        let dailyHours = Int(goal.dailyTime.filter("0123456789".contains)) ?? 1
        let totalAvailableHours = daysUntilDeadline * dailyHours

        // 🧠 STEP 1: Analyze Experience JSON
        var experienceBlock = "The user has not provided any verifiable experience."
        if let exp = experience {
            print("📄 Verified ExperienceProfile JSON:")
            print("Experience Level: \(exp.experienceLevel)")
            print("Skill Sets: \(exp.skillSets.joined(separator: ", "))")
            print("Domain: \(exp.domain)")
            print("Justification: \(exp.justification)")

            experienceBlock = """
            Experience Level: \(exp.experienceLevel)
            Skill Set: \(exp.skillSets.joined(separator: ", "))
            Domain: \(exp.domain)
            Justification: \(exp.justification)
            """
            
            print("\n🧠 AI Reasoning:")
            switch exp.experienceLevel.lowercased() {
            case "advanced":
                print("➡️ This user is experienced. Skip all beginner steps and assume they can move fast.")
                print("➡️ Timeline seems possible if effort aligns with skill. Allow goal as-is.")
            case "intermediate":
                print("⚖️ User has some experience. Include some learning + some execution steps.")
                print("⚖️ Goal deadline is evaluated in balance with user’s history.")
            case "beginner":
                print("⚠️ User is a beginner. AI must slow down and include core foundational steps.")
                print("⚠️ If the goal timeline is too aggressive, adjust roadmap to something realistic.")
            default:
                print("❓ Experience level unclear. Proceed with cautious assumptions.")
            }
        } else {
            print("🕳️ No experience data — AI will assume user is a beginner and adjust accordingly.")
        }

        // 🧠 STEP 2: Inject user data into AI prompt
        let userData = """
        User Goal: \(goal.title)
        Target Deadline: \(goal.targetDeadline) (\(formatter.string(from: deadlineDate)))
        Time Available Per Day: \(dailyHours) hours
        Total Available Time Budget: \(totalAvailableHours) hours
        Current Job: \(user.career)

        \(experienceBlock)

        Build a roadmap that fits within this time budget and is personalized to the user’s actual skills.
        """

        let prompt = "\(systemPrompt)\n\n\(userData)"
        print("\n🧠 AI Prompt Sent:\n\(prompt)\n")

        // 🧠 STEP 3: Check and reuse existing roadmap if present
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Roadmaps", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("\(goal.id.uuidString).json")

        var existingRoadmap: Roadmap?
        var roadmapId: UUID = UUID()

        if FileManager.default.fileExists(atPath: path.path),
           let data = try? Data(contentsOf: path),
           let decoded = try? JSONDecoder().decode(Roadmap.self, from: data) {
            existingRoadmap = decoded
            roadmapId = decoded.id
            print("🔁 Reusing existing roadmapId: \(roadmapId) for goalId: \(goal.id)")
        } else {
            print("🆕 Creating new roadmapId: \(roadmapId) for goalId: \(goal.id)")
        }

        // 🧠 STEP 4: Send to LLM and process response
        queryLLM(prompt: prompt) { raw in
            guard let data = raw.data(using: .utf8) else {
                print("❌ Failed to encode raw AI response.")
                completion([])
                return
            }

            do {
                let steps = try JSONDecoder().decode([RoadmapStep].self, from: data)
                print("✅ AI roadmap decoded")

                if let existing = existingRoadmap,
                   existing.steps.map(\.title) == steps.map(\.title) {
                    print("🚫 Skipping save — roadmap unchanged")
                    completion(existing.steps)
                    return
                }

                let roadmap = Roadmap(
                    id: roadmapId,
                    goalId: goal.id,
                    createdAt: Date(),
                    steps: steps
                )

                RoadmapManager.saveRoadmap(roadmap)

                var stepRequirements: [UUID: [ToolUsageRequirement]] = [:]
                let dailyCommitment = Int(goal.dailyTime) ?? 1
                for step in roadmap.steps {
                    stepRequirements[step.id] = ProgressionEngine.generateRequirements(
                        for: step,
                        dailyCommitmentHours: dailyCommitment
                    )
                }

                BridgeEngine.createProgressionFile(from: roadmap, stepRequirements: stepRequirements)
                completion(steps)

            } catch {
                print("⚠️ JSON decoding failed: \(error)")
                completion([])
            }
        }
    }

    private static func queryLLM(prompt: String, completion: @escaping (String) -> Void) {
        let url = URL(string: "http://localhost:11434/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let json: [String: Any] = [
            "model": "mistral",
            "prompt": prompt,
            "stream": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = try? JSONDecoder().decode(OllamaResponse.self, from: data) else {
                print("❌ LLM response decode failed.")
                completion("[]")
                return
            }
            completion(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }

    private static func parseDeadline(from input: String, now: Date) -> Date {
        let lowercased = input.lowercased()
        if lowercased.contains("day") {
            return Calendar.current.date(byAdding: .day, value: 1, to: now)!
        } else if lowercased.contains("week") {
            return Calendar.current.date(byAdding: .day, value: 7, to: now)!
        } else if lowercased.contains("month") {
            return Calendar.current.date(byAdding: .month, value: 1, to: now)!
        } else if lowercased.contains("year") {
            return Calendar.current.date(byAdding: .year, value: 1, to: now)!
        } else {
            return Calendar.current.date(byAdding: .day, value: 7, to: now)! // fallback
        }
    }
}
