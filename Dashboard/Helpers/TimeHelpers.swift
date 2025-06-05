//
//  TimeHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file contains helper functions related to time formatting,
//  including converting seconds to a readable format and formatting dates.
//

import Foundation

// MARK: - ⏱ Format Time Duration

/// Converts a time duration in seconds to a formatted string (e.g., "1h 20m" or "45m").
/// - Parameter seconds: Duration in seconds.
/// - Returns: A formatted time string.
func formattedTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
}

// MARK: - 📅 Format Date (Private)

/// Formats a Date object into a "M-d-yy" string format.
/// - Parameter date: The Date to format.
/// - Returns: A formatted date string.
/// - Note: This is currently private and used internally.
private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "M-d-yy"
    return formatter.string(from: date)
}

// MARK: - 🔢 Format Duration from Days to Readable Time for RoadMap

/// Converts a duration in fractional days into a human-readable time string
/// (e.g., "2 hrs 30 min", "1 hr", or "45 min").
/// - Parameter days: The duration in days (can be fractional, e.g., 0.1).
/// - Returns: A formatted string representing the equivalent time in hours and minutes.
func formatDurationDays(_ days: Double) -> String {
    let totalMinutes = Int(days * 24 * 60)
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours > 0 && minutes > 0 {
        return "\(hours) hr\(hours > 1 ? "s" : "") \(minutes) min"
    } else if hours > 0 {
        return "\(hours) hr\(hours > 1 ? "s" : "")"
    } else {
        return "\(minutes) min"
    }
}

// MARK: - 🔢 Format Duration from Hours to Readable Time for Progression

/// Converts a time in hours (Double) to a readable "X hr Y min" format.
/// - Parameter hours: Time in hours.
/// - Returns: A string like "1 hr 15 min"
func formatHoursMinutes(_ hours: Double) -> String {
    let totalMinutes = Int(hours * 60)
    let hrs = totalMinutes / 60
    let mins = totalMinutes % 60

    if hrs > 0 && mins > 0 {
        return "\(hrs) hr\(hrs > 1 ? "s" : "") \(mins) min"
    } else if hrs > 0 {
        return "\(hrs) hr\(hrs > 1 ? "s" : "")"
    } else {
        return "\(mins) min"
    }
}

// MARK: - ⏱ Format Duration from Seconds to Readable Time for Tool Progress

/// Converts a duration in seconds to a readable time string
/// (e.g., "1 hr 15 min", "30 min", or "0 min").
/// Handles cases where progress is zero or less than a full minute.
/// - Parameter seconds: The duration in seconds.
/// - Returns: A formatted string representing the equivalent time in hours and minutes.
func formatSecondsToReadable(_ seconds: TimeInterval) -> String {
    if seconds <= 0 {
        return "0 min"
    }

    let totalMinutes = Int(seconds / 60)
    let hrs = totalMinutes / 60
    let mins = totalMinutes % 60

    if hrs > 0 && mins > 0 {
        return "\(hrs) hr\(hrs > 1 ? "s" : "") \(mins) min"
    } else if hrs > 0 {
        return "\(hrs) hr\(hrs > 1 ? "s" : "")"
    } else if mins > 0 {
        return "\(mins) min"
    } else {
        return "<1 min"
    }
}



