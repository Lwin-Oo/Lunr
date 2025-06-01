//
//  CountdownHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 6/1/25.
//
//  This file includes utilities for parsing and formatting deadline durations
//  and computing countdown texts used in the dashboard.
//

import Foundation

// MARK: - ⏳ Countdown Text Formatter

/// Converts a deadline string (e.g., "2025-06-10") into a human-readable countdown like "10 days left".
func countdownText(from deadlineString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    
    if let date = formatter.date(from: deadlineString) {
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysLeft > 0 ? "\(daysLeft) days left" : "⏳ Deadline passed"
    }
    
    return "⏱ \(deadlineString)"
}

// MARK: - 📐 Duration Parser

/// Parses duration strings like "3 days", "2 weeks", "a month" into TimeInterval (in seconds).
func parseDuration(_ input: String) -> TimeInterval? {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    
    // Replace "a" or "an" with "1"
    let normalized = trimmed
        .replacingOccurrences(of: #"(^|\s)(a|an)(?=\s)"#, with: "$11", options: .regularExpression)

    let regex = try! NSRegularExpression(pattern: #"(\d+)\s*(day|week|month)s?"#)

    if let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) {
        let valueRange = Range(match.range(at: 1), in: normalized)
        let unitRange = Range(match.range(at: 2), in: normalized)

        if let valueStr = valueRange.map({ String(normalized[$0]) }),
           let unit = unitRange.map({ String(normalized[$0]) }),
           let value = Int(valueStr) {
            switch unit {
            case "day": return TimeInterval(value * 86400)
            case "week": return TimeInterval(value * 7 * 86400)
            case "month": return TimeInterval(value * 30 * 86400)
            default: return nil
            }
        }
    }

    return nil
}
