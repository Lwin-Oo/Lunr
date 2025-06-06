//
//  LLMClient.swift
//  Lunr
//
//  Created by Lwin Oo on 6/5/25.
//

import Foundation

struct LLMClient {
    static func query(prompt: String, model: String = "mistral", completion: @escaping (String) -> Void) {
        let url = URL(string: "http://localhost:11434/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let json: [String: Any] = [
            "model": model,
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
