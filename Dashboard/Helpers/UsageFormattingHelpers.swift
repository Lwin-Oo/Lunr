//
//  UsageFormattingHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

func formattedUsageData(from sessions: [DailyAppSession]) -> (
    data: [(category: String, total: Double, apps: [(name: String, windowTitle: String, duration: Double)])],
    total: Double
) {
    let nonZeroSessions = sessions.filter { $0.durationSeconds > 0 }

    let grouped = Dictionary(grouping: nonZeroSessions, by: { $0.classification })

    var formatted: [(category: String, total: Double, apps: [(name: String, windowTitle: String, duration: Double)])] = []

    for (category, sessions) in grouped {
        let totalMinutes = sessions.reduce(0.0) { sum, session in
            sum + Double(session.durationSeconds) / 60
        }

        let appsGrouped = Dictionary(grouping: sessions, by: { $0.app })
        var apps: [(String, String, Double)] = []

        for (name, items) in appsGrouped {
            let title = items.last?.windowTitle ?? "Unknown"
            let appMinutes = items.reduce(0.0) { sum, session in
                sum + Double(session.durationSeconds) / 60
            }
            apps.append((name, title, appMinutes))
        }

        apps.sort { $0.2 > $1.2 }

        if totalMinutes > 0 {
            formatted.append((category, totalMinutes, apps))
        }
    }

    formatted.sort { $0.total > $1.total }

    let total = formatted.reduce(0.0) { $0 + $1.total }

    return (formatted, total)
}
