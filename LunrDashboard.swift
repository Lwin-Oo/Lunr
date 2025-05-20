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

struct AppUsageStat: Identifiable {
    let id = UUID()
    let appName: String
    let duration: Int // in seconds
}

struct LunrDashboard: View {
    @State private var isLogging = false
    @State private var usageStats: [AppUsageStat] = []
    @State private var behaviorLog: String = ""
    @State private var terminalLog: String = ""
    @State private var timer: Timer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                ZStack {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 120)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    Text("Productivity Dashboard")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                }

                // Control buttons
                HStack(spacing: 20) {
                    Button(action: startLogging) {
                        Text("Start Logging")
                            .frame(width: 150, height: 44)
                            .background(isLogging ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isLogging)

                    Button(action: stopLogging) {
                        Text("Stop Logging")
                            .frame(width: 150, height: 44)
                            .background(!isLogging ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!isLogging)
                }

                // Stats Overview
                HStack(spacing: 16) {
                    StatCard(title: "Total Apps", value: "\(usageStats.count)")
                    StatCard(title: "Total Time", value: totalFormattedTime())
                    StatCard(title: "Top App", value: usageStats.max(by: { $0.duration < $1.duration })?.appName ?? "-")
                }
                .padding(.horizontal)

                Divider()

                // Chart Section
                if !usageStats.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📈 App Usage Breakdown")
                            .font(.title2)
                            .bold()

                        Chart {
                            ForEach(usageStats.sorted(by: { $0.duration > $1.duration })) { stat in
                                BarMark(
                                    x: .value("App", stat.appName),
                                    y: .value("Duration", stat.duration)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                        }
                        .frame(height: 280)
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                }

                // Behavior Log Section
                if !behaviorLog.isEmpty {
                    InsightCard(title: "🧠 Focus Insights", content: behaviorLog)
                }

                // Terminal Summary Section
                if !terminalLog.isEmpty {
                    InsightCard(title: "📃 Terminal Log", content: terminalLog)
                }

                Spacer().frame(height: 40)
            }
            .padding(.top)
        }
        .onAppear {
            refreshDashboard()
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                refreshDashboard()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func totalFormattedTime() -> String {
        let total = usageStats.map(\.duration).reduce(0, +)
        return "\(total / 60)m \(total % 60)s"
    }

    private func refreshDashboard() {
        let behavior = readLogFile(named: ".lunr_behavior")
        let usageText = readLogFile(named: latestLogFilename())

        DispatchQueue.main.async {
            self.behaviorLog = behavior
            self.usageStats = parseAppUsage(from: usageText)
            self.terminalLog = usageText
        }
    }

    private func startLogging() {
        isLogging = true
        DispatchQueue.global(qos: .background).async { runLogger() }
    }

    private func stopLogging() {
        stopLogger()
        isLogging = false
    }

    private func latestLogFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return "lunr_log_\(today).log"
    }

    private func readLogFile(named filename: String) -> String {
        let fileURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Lunr")
            .appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return "(no log yet)"
        }

        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "(no log yet)" : content
        } catch {
            print("❌ Failed to read \(filename): \(error.localizedDescription)")
            return "(failed to read file)"
        }
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

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(.primary)
            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(width: 120, height: 80)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct InsightCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3).bold()
            ScrollView {
                Text(content)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(10)
            }
            .frame(minHeight: 150)
        }
        .padding(.horizontal)
    }
}
