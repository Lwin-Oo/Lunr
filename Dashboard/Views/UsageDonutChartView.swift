//
//  UsageDonutChartView.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
// This view visualizes categorized app usage time in a donut chart. It allows users to tap on chart segments to view breakdowns by app within each category.

import SwiftUI
import Charts

// MARK: - 🧱 BreakdownItem
/// Represents a single app usage entry used in breakdown views under a selected category.
struct BreakdownItem: Identifiable {
    let id = UUID()
    let app: String
    let duration: TimeInterval
}

// MARK: - 🍩 UsageDonutChartView
struct UsageDonutChartView: View {
    let sessions: [DailyAppSession]
    @State private var selectedCategory: String?
    
    private var groupedData: [(category: String, duration: TimeInterval)] {
        let byCat = Dictionary(grouping: sessions) {
            mapToMainCategory($0.classification)
        }
        return byCat.map { (cat, items) in
            (cat, items.reduce(0) { $0 + TimeInterval($1.durationSeconds) })
        }
        .sorted { $0.duration > $1.duration }
    }
    
    private var totalDuration: TimeInterval {
        groupedData.map(\.duration).reduce(0, +)
    }
    
    private var breakdownData: [BreakdownItem] {
        guard let sel = selectedCategory else { return [] }
        let filtered = sessions.filter { mapToMainCategory($0.classification) == sel }
        let byApp = Dictionary(grouping: filtered, by: { $0.app })
        let result = byApp.map { (app, items) in
            BreakdownItem(app: app, duration: items.reduce(0) { $0 + TimeInterval($1.durationSeconds) })
        }
            .sorted { $0.duration > $1.duration }
        
        // Log for debug
        print("🧩 Selected Category: \(sel)")
        print("📦 Breakdown Count: \(result.count)")
        for b in result {
            print("🔹 App: \(b.app), Duration: \(formatDuration(b.duration))")
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🧭 Time by Category")
                .font(.title3.bold())
            
            ZStack {
                Chart {
                    ForEach(groupedData, id: \.category) { item in
                        SectorMark(
                            angle: .value("Duration", item.duration),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(colorForMainCategory(item.category))
                    }
                }
                .chartLegend(.hidden)
                .frame(width: 240, height: 240)
                .padding(.top, 12)
                .chartOverlay { _ in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                                        let dx = value.location.x - center.x
                                        let dy = value.location.y - center.y
                                        var angle = atan2(dy, dx) * 180 / .pi + 90
                                        if angle < 0 { angle += 360 }
                                        
                                        var startAngle = 0.0
                                        for item in groupedData {
                                            let span = (item.duration / max(totalDuration, 1)) * 360
                                            if angle >= startAngle && angle < startAngle + span {
                                                selectedCategory = item.category
                                                print("✅ Selected category: \(item.category)")
                                                break
                                            }
                                            startAngle += span
                                        }
                                    }
                            )
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(groupedData, id: \.category) { item in
                    HStack {
                        Circle()
                            .fill(colorForMainCategory(item.category))
                            .frame(width: 8, height: 8)
                        Text("\(item.category): \(formatDuration(item.duration))")
                            .font(.caption)
                        if item.category == selectedCategory {
                            Text("✓")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }
            }
            
            if let cat = selectedCategory {
                Divider().padding(.vertical, 4)
                Text("Breakdown for \(cat)")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if breakdownData.isEmpty {
                    Text("No data for this category.")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(breakdownData) { row in
                                HStack(alignment: .top) {
                                    Text(row.app)
                                        .font(.caption2.bold())
                                    Spacer()
                                    Text(formatDuration(row.duration))
                                        .font(.caption2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 150)
                    //          .border(Color.red)
                }
            }
        }
        .padding()
    }
}
