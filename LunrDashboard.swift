//
//  LunrDashboard.swift
//  Lunr
//
//  Created by Lwin Oo on 5/19/25.
//

import SwiftUI
import Charts

@_silgen_name("runLogger") func runLogger()
@_silgen_name("stopLogger") func stopLogger()

@objc class SystemObserver: NSObject {
    @objc static func getCurrentAppName() -> String { "Unknown" }
    @objc static func getCurrentTabTitle() -> String { "Unknown" }
}

struct AppUsageStat: Identifiable {
    let id = UUID()
    let appName: String
    let duration: Int
}

struct LunrDashboard: View {
    @State private var isLogging = false
    @State private var usageStats: [AppUsageStat] = []
    @State private var behaviorLog: String = ""
    @State private var terminalLog: String = ""
    @State private var classifierSummaries: String = ""
    @State private var activeTabTitle: String = "-"
    @State private var timer: Timer? = nil
    @StateObject private var screenRecorder = ScreenRecorder()

    var totalTime: Int {
        usageStats.map(\.duration).reduce(0, +)
    }

    var productivityBreakdown: [(label: String, duration: Int, color: Color)] {
        var productive = 0, entertaining = 0, unknown = 0
        for stat in usageStats {
            let lower = stat.appName.lowercased()
            if lower.contains("xcode") || lower.contains("terminal") || lower.contains("code") {
                productive += stat.duration
            } else if lower.contains("youtube") || lower.contains("netflix") || lower.contains("spotify") {
                entertaining += stat.duration
            } else {
                unknown += stat.duration
            }
        }

        var breakdown: [(String, Int, Color)] = []
        if productive > 0 { breakdown.append(("Productive", productive, .green)) }
        if entertaining > 0 { breakdown.append(("Entertaining", entertaining, .red)) }
        if productive == 0 && entertaining == 0 && unknown > 0 {
            breakdown.append(("Unknown", unknown, .gray))
        }

        return breakdown
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Text("📊 Daily Productivity Overview")
                    .font(.system(size: 28, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24)
                    .padding(.horizontal)

                HStack(spacing: 20) {
                    StatCard(title: "Total Apps", value: "\(usageStats.count)")
                    StatCard(title: "Total Time", value: formattedTime(totalTime))
                    StatCard(title: "Top App", value: usageStats.max(by: { $0.duration < $1.duration })?.appName ?? "-")
                    StatCard(title: "Active Tab", value: activeTabTitle)
                }
                .padding(.horizontal)

                Divider().padding(.horizontal)

                if totalTime > 0 && !productivityBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("🎯 Productivity Breakdown")
                            .font(.title3).bold()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Chart {
                            ForEach(productivityBreakdown, id: \.label) { segment in
                                SectorMark(
                                    angle: .value("Time", segment.duration),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1
                                )
                                .foregroundStyle(segment.color)
                                .annotation(position: .overlay) {
                                    Text(segment.label).font(.caption)
                                }
                            }
                        }
                        .frame(height: 240)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }

                if !usageStats.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⏱️ App Usage (Time Spent)").font(.title3).bold()
                        Chart(usageStats.sorted(by: { $0.duration > $1.duration })) {
                            BarMark(
                                x: .value("App", $0.appName),
                                y: .value("Duration", $0.duration)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                        .frame(height: 300)
                    }
                    .padding(.horizontal)
                }

                if !behaviorLog.isEmpty {
                    InsightCard(title: "🧠 Focus Insights", content: behaviorLog)
                }

                if !terminalLog.isEmpty {
                    InsightCard(title: "📃 Terminal Log", content: terminalLog)
                }

                if !classifierSummaries.isEmpty {
                    InsightCard(title: "🧠 Classifier Summary", content: classifierSummaries)
                }

                Spacer(minLength: 40)
            }
        }
        .padding(.bottom)
        .onAppear {
            refreshDashboard()
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                refreshDashboard()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .navigationTitle("Lunr Dashboard")
        .toolbar {
            Button(isLogging ? "Stop Logging" : "Start Logging") {
                isLogging ? stopLogging() : startLogging()
            }
            .padding(8)
            .background(isLogging ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }

    private func startLogging() {
        isLogging = true
        screenRecorder.start()
        DispatchQueue.global(qos: .background).async { runLogger() }
    }

    private func stopLogging() {
        stopLogger()
        screenRecorder.stop()
        isLogging = false
    }

    private func formattedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins)m \(secs)s"
    }

    private func refreshDashboard() {
        let behavior = readLogFile(named: ".lunr_behavior")
        let usageText = readLatestUsageLogFromContainer()
        let debugSummary = readDebugSummary()
        let appName = SystemObserver.getCurrentAppName()
        let tabTitle = SystemObserver.getCurrentTabTitle()

        DispatchQueue.main.async {
            self.behaviorLog = behavior
            self.usageStats = parseAppUsage(from: usageText)
            self.terminalLog = usageText
            self.classifierSummaries = debugSummary
            self.activeTabTitle = "\(appName): \(tabTitle)"
        }
    }

    private func readLogFile(named filename: String) -> String {
        let url = URL(fileURLWithPath: "/Users/Shared/\(filename)")
        guard FileManager.default.fileExists(atPath: url.path) else {
            return "(no log yet)"
        }
        return (try? String(contentsOf: url, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(failed to read file)"
    }

    private func readLatestUsageLogFromContainer() -> String {
        let supportDir = "/Users/lwi/Library/Containers/Oo.Lunr/Data/Library/Application Support/Lunr"
        let fm = FileManager.default

        guard let files = try? fm.contentsOfDirectory(atPath: supportDir) else {
            return "(no log yet)"
        }

        let latestLog = files
            .filter { $0.hasPrefix("lunr_log_") && $0.hasSuffix(".log") }
            .sorted()
            .last

        guard let logFile = latestLog else { return "(no log found)" }

        let fullPath = "\(supportDir)/\(logFile)"
        return (try? String(contentsOfFile: fullPath, encoding: .utf8)) ?? "(failed to read usage log)"
    }

    private func readDebugSummary() -> String {
        let path = "/tmp/lunr_debug.log"
        guard FileManager.default.fileExists(atPath: path) else { return "(no classifier log)" }
        return (try? String(contentsOfFile: path, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "(failed to read classifier log)"
    }

    private func parseAppUsage(from content: String) -> [AppUsageStat] {
        var stats: [AppUsageStat] = []
        for line in content.split(separator: "\n") {
            guard line.contains(",") else { continue }
            let parts = line.split(separator: ",", omittingEmptySubsequences: true)
            guard parts.count == 2 else { continue }
            let app = String(parts[0])
            let time = parts[1].trimmingCharacters(in: .whitespaces)
            let timeParts = time.split(separator: " ")
            guard timeParts.count == 2 else { continue }
            let mins = Int(timeParts[0].dropLast()) ?? 0
            let secs = Int(timeParts[1].dropLast()) ?? 0
            stats.append(AppUsageStat(appName: app, duration: mins * 60 + secs))
        }
        return stats
    }
}

// MARK: - StatCard
struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2).bold()
            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - InsightCard
struct InsightCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(10)
            }
            .frame(minHeight: 160)
        }
        .padding(.horizontal)
    }
}
