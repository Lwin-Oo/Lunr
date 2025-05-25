//
//  Goal.swift
//  Lunr
//
//  Created by Lwin Oo on 5/24/25.
//

import Foundation

struct Goal: Codable, Identifiable {
    var id = UUID()
    var title: String              // Milestone
    var targetDeadline: String     // When user wants it done
    var realisticEstimate: String  // When user thinks it's realistic
    var dailyTime: String          // Daily commitment
    var createdAt: Date
}

