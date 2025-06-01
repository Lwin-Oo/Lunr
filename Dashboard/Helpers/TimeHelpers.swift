//
//  TimeHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

// TimeHelpers.swift
import Foundation

func formattedTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
}

