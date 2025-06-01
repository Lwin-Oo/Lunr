//
//  SummaryCardsSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import SwiftUI

struct SummaryCardsSection: View {
    let sessionCount: Int
    let totalTimeFormatted: String

    var body: some View {
        HStack(spacing: 16) {
            SummaryCard(title: "Sessions", value: "\(sessionCount)")
            SummaryCard(title: "Total Time", value: totalTimeFormatted)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).bold()
            Text(title).font(.caption).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
