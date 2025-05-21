//
//  ContentClassifier.swift
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

import Foundation
import NaturalLanguage

enum ActivityType: String {
    case work = "Work"
    case entertainment = "Entertainment"
    case unknown = "Unknown"
}

class ContentClassifier {
    static let shared = ContentClassifier()

    private let workKeywords: Set<String> = [
        "code", "programming", "tutorial", "design", "course", "research", "how to", "documentary", "learning"
    ]

    private let entertainmentKeywords: Set<String> = [
        "anime", "netflix", "comedy", "trailer", "gameplay", "movie", "episode", "funny", "music", "meme"
    ]

    private init() {}

    func classify(_ text: String) -> ActivityType {
        let lowercased = text.lowercased()

        for keyword in workKeywords where lowercased.contains(keyword) {
            return .work
        }

        for keyword in entertainmentKeywords where lowercased.contains(keyword) {
            return .entertainment
        }

        return .unknown
    }
}
