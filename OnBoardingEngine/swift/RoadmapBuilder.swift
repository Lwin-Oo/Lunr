//
//  RoadmapBuilder.swift
//  Lunr
//
//  Created by Lwin Oo on 5/24/25.
//

import Foundation

class RoadmapBuilder {
    static func buildRoadmap(for user: User, goal: Goal, completion: @escaping ([RoadmapStep]) -> Void) {
        let systemPrompt = """
        You are a productivity coach. Given the following user data, generate a JSON array of roadmap steps to help them reach their goal.

        Each roadmap step should include:
        - title (string)
        - durationDays (decimal number, e.g., 0.5 means 12 hours)
        - toolsOrResources (array of strings)
        - description (1-2 sentence summary)

        Respond ONLY with the raw JSON array. Do not include any explanation or extra characters.
        """

        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let now = Date()
        let deadlineDate = parseDeadline(from: goal.targetDeadline, now: now)
        let daysUntilDeadline = max(Calendar.current.dateComponents([.day], from: now, to: deadlineDate).day ?? 1, 1)

        let dailyHours = Int(goal.dailyTime.filter("0123456789".contains)) ?? 1
        let totalAvailableHours = daysUntilDeadline * dailyHours

        let userData = """
        User Goal: \(goal.title)
        Target Deadline: \(goal.targetDeadline) (\(formatter.string(from: deadlineDate)))
        You have \(daysUntilDeadline) day(s) until the deadline.
        Time Available Per Day: \(dailyHours) hours
        Total Available Time Budget: \(totalAvailableHours) hours
        Current Job: \(user.career)

        Build a roadmap that fits within this total time budget.
        """

        let prompt = "\(systemPrompt)\n\n\(userData)"

        print("🧠 Sending Prompt to AI:\n\(prompt)\n")

        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Roadmaps", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("\(goal.id.uuidString).json")

        // 🔒 FIXED: Always reuse existing roadmap ID and prevent overwrite
        var existingRoadmap: Roadmap?
        var roadmapId: UUID = UUID()

        if FileManager.default.fileExists(atPath: path.path),
           let data = try? Data(contentsOf: path),
           let decoded = try? JSONDecoder().decode(Roadmap.self, from: data) {
            existingRoadmap = decoded
            roadmapId = decoded.id
            print("🔁 Reusing existing roadmapId: \(roadmapId) for goalId: \(goal.id)")
        } else {
            print("🆕 Generated NEW roadmapId: \(roadmapId) for goalId: \(goal.id)")
        }

        queryLLM(prompt: prompt) { raw in
            print("📥 Raw AI Response:\n\(raw)\n")

            guard let data = raw.data(using: .utf8) else {
                print("❌ Failed to encode raw response into Data")
                completion([])
                return
            }

            do {
                let steps = try JSONDecoder().decode([RoadmapStep].self, from: data)
                print("✅ Successfully decoded roadmap steps")

                // Check if we already have the same steps, avoid regenerating
                if let existing = existingRoadmap,
                   existing.steps.map(\.title) == steps.map(\.title) {
                    print("🚫 Existing roadmap matches AI response. Skipping overwrite + progression.")
                    completion(existing.steps)
                    return
                }

                let roadmap = Roadmap(
                    id: roadmapId,
                    goalId: goal.id,
                    createdAt: Date(),
                    steps: steps
                )

                print("📦 Preparing to save ROADMAP")
                print("🧭 goalId: \(goal.id)")
                print("🧭 roadmapId: \(roadmapId)")
                print("📂 Target path: \(path.path)")

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
                print("⚠️ Failed to decode roadmap steps: \(error)")
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


