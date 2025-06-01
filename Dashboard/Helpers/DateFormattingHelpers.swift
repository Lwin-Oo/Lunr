//
//  DateFormattingHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file provides helper functions for formatting Date objects into readable display strings.
//

import Foundation

// MARK: - 📅 Date Formatter

/// Formats a Date into a medium style string (e.g., "Jun 1, 2025").
func formattedDisplayDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}
