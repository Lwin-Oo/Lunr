//
//  LunrDashboard.swift
//  Lunr
//
//  Created by Lwin Oo on 5/19/25.
//

import SwiftUI

struct LunrDashboard: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var selectedDate = Date()
    @State private var usageData: [DailyAppSession] = []
    @State private var isMonitoring = MonitoringEngine.shared.isRunning

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if currentPhase == .observation {
                        observationPhaseView
                    } else {
                        dashboardView
                    }
                }
                .padding()
            }
            .navigationTitle("Lunr OS")
            .onAppear {
                loadData(for: selectedDate)
                isMonitoring = MonitoringEngine.shared.isRunning

            }
        }
    }

    enum Phase {
        case observation, dashboard
    }

    var currentPhase: Phase {
        let count = availableLogDatesWithSessions().count
        return count < 7 ? .observation : .dashboard
    }

    // MARK: - Observation Phase

    private var observationPhaseView: some View {
        VStack(spacing: 20) {
            Text("🧭 Week 1: Observation Phase")
                .font(.title2.bold())

            Text("Lunr is monitoring your daily activity.\nWe’ll begin your dashboard after 1 week.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)

            Text("Day \(availableLogDatesWithSessions().count + 1) of 7")
                .font(.headline)

            Text("Status: \(isMonitoring ? "Running" : "Not Running")")
                .foregroundColor(isMonitoring ? .green : .red)
                .font(.caption)

            Button(isMonitoring ? "Stop Monitoring" : "Start Monitoring") {
                toggleMonitoring()
            }
            .padding()
            .frame(maxWidth: 220)
            .background(isMonitoring ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Dashboard Phase

    private var dashboardView: some View {
        VStack(spacing: 24) {
            headerSection
            calendarPickerSection
            summaryCardsSection
            categorizedUsageSection
            rawLogSection
        }
    }

    private var headerSection: some View {
        Group {
            if let user = userManager.currentUser {
                VStack(alignment: .leading, spacing: 4) {
                    Text("👋 Welcome, \(user.name)")
                        .font(.title2.bold())
                    Text("🎯 Goal: \(user.milestone)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                EmptyView()
            }
        }
    }

    private var calendarPickerSection: some View {
        HStack {
            DatePicker("Pick a Date", selection: $selectedDate, displayedComponents: .date)
                .onChange(of: selectedDate) { loadData(for: $0) }

            Spacer()

            Button("Reset") {
                selectedDate = Date()
                loadData(for: Date())
            }
        }
    }

    private var summaryCardsSection: some View {
        HStack(spacing: 16) {
            SummaryCard(title: "Sessions", value: "\(usageData.count)")
            SummaryCard(title: "Total Time", value: formattedTotalTime())
        }
    }

    private var categorizedUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Usage by Category").font(.headline)
            ForEach(["Productive", "Entertaining", "Unknown"], id: \.self) { category in
                let items = usageData.filter { $0.classification == category }
                if !items.isEmpty {
                    DisclosureGroup("\(category) (\(items.count))") {
                        ForEach(items) { session in
                            VStack(alignment: .leading) {
                                Text("• \(session.app)").bold()
                                Text(session.windowTitle).font(.caption).foregroundColor(.gray)
                                Text("⏱ \(formattedTime(session.durationSeconds))").font(.caption2)
                            }
                        }
                    }
                }
            }
        }
    }

    private var rawLogSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🧾 Raw Data Access").font(.headline)
            Button("Open JSON File in Finder") {
                openLogInFinder()
            }
            .font(.caption)
        }
    }

    // MARK: - Helpers

    private func toggleMonitoring() {
        if isMonitoring {
            stopLogger()
            MonitoringEngine.shared.stop()
        } else {
            runLogger()
            MonitoringEngine.shared.start()
        }
        isMonitoring = MonitoringEngine.shared.isRunning
    }



    private func loadData(for date: Date) {
        let filename = formattedDate(date) + ".json"
        let path = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/logs/\(filename)")
        if let data = try? Data(contentsOf: path),
           let decoded = try? JSONDecoder().decode(DailyLog.self, from: data) {
            usageData = decoded.sessions
        } else {
            usageData = []
        }
    }

    private func availableLogDatesWithSessions() -> [Date] {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Lunr/logs")
        let files = (try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)) ?? []
        return files.compactMap {
            guard let data = try? Data(contentsOf: $0),
                  let log = try? JSONDecoder().decode(DailyLog.self, from: data),
                  !log.sessions.isEmpty else { return nil }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            return df.date(from: log.date)
        }

    }

    private func openLogInFinder() {
        let fileURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/logs/\(formattedDate(selectedDate)).json")
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formattedTotalTime() -> String {
        let total = usageData.reduce(0) { $0 + $1.durationSeconds }
        return formattedTime(total)
    }

    private func formattedTime(_ seconds: Int) -> String {
        "\(seconds / 60)m \(seconds % 60)s"
    }
}

// MARK: - SummaryCard

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
