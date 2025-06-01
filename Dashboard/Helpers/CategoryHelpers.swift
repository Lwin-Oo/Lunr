//
//  CategoryHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 6/1/25.
//
//  This file contains helper functions used for classifying, formatting,
//  and styling categorized usage data in the Lunr Dashboard.
//

import Foundation
import SwiftUI

// MARK: - ⏱ Duration Formatter

/// Formats a TimeInterval (in seconds) into a human-readable string like "2h 15m" or "5m".
public func formatDuration(_ d: TimeInterval) -> String {
    let m = Int(d) / 60, h = m / 60, r = m % 60
    return h > 0 ? "\(h)h \(r)m" : "\(r)m"
}

// MARK: - 🧠 Category Mapping

/// Maps detailed activity classification strings (e.g. "code", "gaming") into main categories: Productivity, Entertainment, or Utils.
public func mapToMainCategory(_ c: String) -> String {
    let l = c.lowercased()
    if l.contains("code") || l.contains("design") || l.contains("writing") || l.contains("productive") {
        return "Productivity"
    } else if l.contains("entertainment") || l.contains("gaming") || l.contains("social") {
        return "Entertainment"
    }
    return "Utils"
}

// MARK: - 🎨 Category Color

/// Returns a Color used for visualizing each main category (e.g. Productivity = blue).
public func colorForMainCategory(_ cat: String) -> Color {
    switch cat {
    case "Productivity": return .blue
    case "Entertainment": return .orange
    case "Utils": return .gray
    default: return .black
    }
}

