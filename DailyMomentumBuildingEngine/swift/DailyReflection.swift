//
//  DailyReflection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/26/25.
//

import Foundation

struct DailyReflection: Codable {
    let date: Date
    var mood: String
    var topFocus: String
    var smallWin: String
}
