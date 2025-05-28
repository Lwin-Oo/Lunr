//
//  FlatDailyAppSession.swift
//  Lunr
//
//  Created by Lwin Oo on 5/27/25.
//

struct FlatDailyAppSession: Codable, Identifiable {
    let id: String
    let classification: String
    let app: String
    let windowTitle: String
    let startTime: String
    let endTime: String
    let durationSeconds: Int
}

struct FlatDailyLog: Codable {
    let date: String
    let periods: [String: [FlatDailyAppSession]]
}
