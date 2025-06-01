//
//  CategorizedUsageSection.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import SwiftUI
import Charts

struct CategorizedUsageSection: View {
    let sessions: [DailyAppSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Time by Category")
                .font(.headline)

            if sessions.isEmpty {
                Text("No usage data to display.")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                UsageDonutChartView(sessions: sessions)
                    .frame(height: 260)
            }
        }
        .padding(.horizontal)
    }
}
