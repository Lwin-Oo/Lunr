//
//  User.swift
//  Lunr
//
//  Created by Lwin Oo on 5/23/25.
//

import Foundation

struct User: Codable {
    var name: String
    var milestone: String
    var targetDeadline: String
    var realisticEstimate: String
    var createdAt: Date
    var lastActive: Date
}


