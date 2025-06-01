//
//  DateUtils.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file includes utility functions for parsing date strings into Date objects.
//

import Foundation


// MARK: - 📅 Parse Deadline String to Date

/// Parses a date string formatted as "yyyy-MM-dd" into a `Date` object.
/// - Parameter string: The deadline string (e.g., "2025-06-01").
/// - Returns: A `Date` if parsing succeeds, otherwise `nil`.
func parseDeadline(_ string: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: string)
}
