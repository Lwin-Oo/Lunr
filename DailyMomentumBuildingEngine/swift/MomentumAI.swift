//
//  MomentumAI.swift
//  Lunr
//
//  Created by Lwin Oo on 5/26/25.
//

//
//  MomentumAI.swift
//  Lunr
//
//  Created by Lwin Oo on 5/26/25.
//

import Foundation

final class MomentumAI {
    static func generateEncouragement(from reflection: DailyReflection, weather: WeatherData, date: Date = Date(), completion: @escaping (String) -> Void) {
        let dayName = DateFormatter().weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]
        let mood = reflection.mood.lowercased()
        let focus = reflection.topFocus.trimmingCharacters(in: .whitespaces)

        let prompt = """
        You are a motivational AI coach.
        Based on the user's mood, weather, and focus for the day, craft a short motivational message.

        - Mood: \(mood)
        - Today's focus: \(focus)
        - Weather: \(weather.condition), \(Int(weather.temperature))°C
        - Day: \(dayName)

        Keep it realistic and grounded. No fluff. Max 3 sentences.
        """

        queryLLM(prompt: prompt) { response in
            completion(response)
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
                  let result = try? JSONDecoder().decode(OllamaResponse.self, from: data)
            else {
                completion("🌥️ AI failed to respond.")
                return
            }
            completion(result.response.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}
