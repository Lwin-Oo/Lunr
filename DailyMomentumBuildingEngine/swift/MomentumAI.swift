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

        LLMClient.query(prompt: prompt, completion: completion)
    }
}


