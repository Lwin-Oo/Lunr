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
