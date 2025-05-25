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
    @State private var roadmap: [RoadmapStep] = []
    @State private var isMonitoring = MonitoringEngine.shared.isRunning

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    roadmapSection
                    monitoringToggleSection
                    calendarPickerSection
                    summaryCardsSection
                    categorizedUsageSection
                    rawLogSection
                }
                .padding()
            }
            .navigationTitle("Lunr OS")
            .onAppear {
                loadData(for: selectedDate)
                loadRoadmap()
                isMonitoring = MonitoringEngine.shared.isRunning
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Group {
            if let user = userManager.currentUser,
               let goal = loadGoal(for: user) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("👋 Welcome, \(user.name)").font(.title2.bold())
                    Text("🎯 Goal: \(goal.title)").font(.subheadline).foregroundColor(.gray)
                }
            } else {
                EmptyView()
            }
        }
    }


    // MARK: - Roadmap

    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📅 Your Roadmap").font(.headline)
            if roadmap.isEmpty {
                Text("LLM is still generating your roadmap...").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(roadmap) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• \(step.title)").bold()
                        Text("⏱ \(step.durationDays) days")
                        Text("📦 \(step.toolsOrResources.joined(separator: ", "))").font(.caption)
                        Text(step.description).font(.caption2).foregroundColor(.gray)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }
    
    private var monitoringToggleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🖥 Screen Monitoring").font(.headline)

            Text("Status: \(isMonitoring ? "Running" : "Stopped")")
                .font(.caption)
                .foregroundColor(isMonitoring ? .green : .red)

            Button(action: toggleMonitoring) {
                Text(isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isMonitoring ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .frame(maxWidth: 200)
        }
    }


    // MARK: - Calendar

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

    // MARK: - Summary

    private var summaryCardsSection: some View {
        HStack(spacing: 16) {
            SummaryCard(title: "Sessions", value: "\(usageData.count)")
            SummaryCard(title: "Total Time", value: formattedTotalTime())
        }
    }

    // MARK: - Usage Logs

    private var categorizedUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Usage by Category").font(.headline)
            ForEach(["Productive", "Entertainment", "Code", "Educational", "Social", "Utility", "Communication", "Design", "Gaming", "Uncategorized"], id: \.self) { category in
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

            Divider()

            Button(role: .destructive) {
                destroyUserData()
            } label: {
                Label("Destroy User", systemImage: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
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
    
    private func loadGoal(for user: User) -> Goal? {
        let goalsDir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Goals")

        guard let files = try? FileManager.default.contentsOfDirectory(at: goalsDir, includingPropertiesForKeys: nil) else {
            return nil
        }

        // Load the most recent goal for this user (you could improve with actual user-goal mapping later)
        for file in files.reversed() {
            if let data = try? Data(contentsOf: file),
               let goal = try? JSONDecoder().decode(Goal.self, from: data) {
                return goal
            }
        }

        return nil
    }


    private func loadRoadmap() {
        guard let user = userManager.currentUser,
              let goal = loadGoal(for: user) else {
            print("❌ No user or goal found for roadmap loading.")
            return
        }

        let roadmapPath = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Roadmaps/\(goal.id.uuidString).json")

        print("📁 Trying to load roadmap from: \(roadmapPath.path)")

        guard let data = try? Data(contentsOf: roadmapPath) else {
            print("❌ Failed to load roadmap data from file.")
            return
        }

        guard let roadmapObj = try? JSONDecoder().decode(Roadmap.self, from: data) else {
            print("❌ Failed to decode roadmap from JSON.")
            return
        }

        DispatchQueue.main.async {
            print("✅ Successfully loaded roadmap with \(roadmapObj.steps.count) steps.")
            self.roadmap = roadmapObj.steps
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
    
    private func destroyUserData() {
        guard let user = userManager.currentUser else { return }

        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("Lunr")

        let userDir = base.appendingPathComponent("users/\(user.name)")
        let logsDir = base.appendingPathComponent("logs")

        try? FileManager.default.removeItem(at: userDir)
        try? FileManager.default.removeItem(at: logsDir)

        userManager.currentUser = nil
        userManager.isUserLoaded = true // reset so onboarding shows
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
