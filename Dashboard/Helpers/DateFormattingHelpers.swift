//
//  DateFormattingHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

func formattedDisplayDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}
