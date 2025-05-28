//
//  DailyAppSession.swift
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

import Foundation

struct DailyAppSession: Codable, Identifiable {
    let id = UUID()
    let app: String
    let windowTitle: String
    let startTime: String
    let endTime: String
    let durationSeconds: Int
    let classification: String
}

struct DailyLog: Codable {
    let date: String
    var sessions: [DailyAppSession]?
    var periods: [PeriodSessionGroup]?

    enum CodingKeys: String, CodingKey {
        case date, periods
    }

    // ✅ Manual decoding for JSON with dictionary periods
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        let rawPeriods = try container.decode([String: [DailyAppSession]].self, forKey: .periods)
        periods = rawPeriods.map { PeriodSessionGroup(period: $0.key, sessions: $0.value) }
        sessions = periods?.flatMap { $0.sessions }
    }

    // ✅ Manual initializer for creating from code (like when saving)
    init(date: String, periods: [PeriodSessionGroup]) {
        self.date = date
        self.periods = periods
        self.sessions = periods.flatMap { $0.sessions }
    }
}



struct PeriodSessionGroup: Codable {
    let period: String
    let sessions: [DailyAppSession]
}
