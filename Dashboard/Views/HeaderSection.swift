//
//  HeaderSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import SwiftUI

struct HeaderSection: View {
    let user: User?
    let goal: Goal?
    let countdownText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let user = user, let goal = goal {
                Text("👋 Welcome, \(user.name)").font(.title2.bold())

                HStack(spacing: 12) {
                    Text("🎯 Current Goal: \(goal.title)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(countdownText)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                Text("🔒 No user loaded").font(.subheadline)
            }
        }
    }
}
