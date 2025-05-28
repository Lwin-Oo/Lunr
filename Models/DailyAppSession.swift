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
}

struct PeriodSessionGroup: Codable {
    let period: String
    let sessions: [DailyAppSession]
}
