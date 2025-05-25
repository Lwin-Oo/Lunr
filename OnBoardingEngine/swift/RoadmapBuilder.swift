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
        - durationDays (int)
        - toolsOrResources (array of strings)
        - description (1-2 sentence summary)

        Respond ONLY with the raw JSON array. Do not include any explanation or extra characters.
        """

        let userData = """
        User Goal: \(goal.title)
        Target Deadline: \(goal.targetDeadline)
        Realistic Estimate: \(goal.realisticEstimate)
        Time Available Per Day: \(goal.dailyTime)
        Current Job: \(user.career)
        """

        let prompt = "\(systemPrompt)\n\n\(userData)"

        print("🧠 Sending Prompt to AI:\n\(prompt)\n")

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
}
