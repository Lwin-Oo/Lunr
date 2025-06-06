//
//  OnboardingStep.swift
//  Lunr
//
//  Created by Lwin Oo on 6/5/25.
//

import Foundation

enum OnboardingStep: String, CaseIterable {
    case milestone
    case experienceCheck   // ✅ yes/no
    case experienceDesc    // ✍️ sentence
    case experienceLink    // 🔗 link
    case success
    case deadline
    case estimation
    case dailyTime
    case career
    case name
}

