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
    @State private var countdownText: String = ""
    @State private var countdownTimer: Timer?

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
                loadAllGoalRoadmaps()
                isMonitoring = MonitoringEngine.shared.isRunning
                startCountdown()
            }

        }
    }
    
    private func currentRoadmapStepIndex(for roadmap: Roadmap) -> Int? {
        var accumulatedDays = 0
        let now = Date()

        for (index, step) in roadmap.steps.enumerated() {
            let stepStart = Calendar.current.date(byAdding: .day, value: accumulatedDays, to: roadmap.createdAt) ?? roadmap.createdAt
            accumulatedDays += step.durationDays
            let stepEnd = Calendar.current.date(byAdding: .day, value: step.durationDays, to: stepStart) ?? stepStart

            if now >= stepStart && now < stepEnd {
                return index
            }
        }

        return nil
    }

    
    private func startCountdown() {
        countdownTimer?.invalidate()

        guard let user = userManager.currentUser,
              let goal = loadGoal(for: user) else {
            countdownText = "No deadline"
            return
        }

        // Convert goal.createdAt from Double to Date
        let startDate = Date(timeIntervalSince1970: goal.createdAt.timeIntervalSince1970)

        guard let deadlineInterval = parseDuration(goal.targetDeadline) else {
            countdownText = "⏳ Invalid deadline"
            return
        }

        let targetDate = startDate.addingTimeInterval(deadlineInterval)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let now = Date()
            let remaining = targetDate.timeIntervalSince(now)

            if remaining <= 0 {
                countdownText = "⏳ Deadline passed"
                countdownTimer?.invalidate()
            } else {
                let days = Int(remaining) / 86400
                let hours = (Int(remaining) % 86400) / 3600
                let minutes = (Int(remaining) % 3600) / 60
                let seconds = Int(remaining) % 60
                countdownText = "⏳ Expires in: \(days)d \(hours)h \(minutes)m \(seconds)s"
            }
        }
    }


    
    private func countdownText(from deadlineString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Try parsing string as exact date first (if you later use exact dates)
        if let date = formatter.date(from: deadlineString) {
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
            return daysLeft > 0 ? "\(daysLeft) days left" : "⏳ Deadline passed"
        }

        // If using freeform like "3 months", show it as-is
        return "⏱ \(deadlineString)"
    }

    private func parseDuration(_ input: String) -> TimeInterval? {
        let lowercased = input.lowercased()
        let components = lowercased.components(separatedBy: " ")
        guard components.count >= 2,
              let value = Int(components[0]) else { return nil }

        if components[1].starts(with: "day") {
            return TimeInterval(value * 86400)
        } else if components[1].starts(with: "week") {
            return TimeInterval(value * 7 * 86400)
        } else if components[1].starts(with: "month") {
            return TimeInterval(value * 30 * 86400)
        }

        return nil
    }

    
    // MARK: - Header

    private var headerSection: some View {
        Group {
            if let user = userManager.currentUser,
               let goal = loadGoal(for: user) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("👋 Welcome, \(user.name)").font(.title2.bold())

                    HStack(spacing: 12) {
                        Text("🎯 Current Goal: \(goal.title)").font(.subheadline).foregroundColor(.gray)
                        Text(countdownText).font(.subheadline).foregroundColor(.blue)
                    }

                }
            } else {
                EmptyView()
            }
        }
    }



    // MARK: - Roadmap

    @State private var goalRoadmaps: [(Goal, Roadmap)] = []
    @State private var expandedStepsByGoal: [UUID: Set<UUID>] = [:]

    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if goalRoadmaps.isEmpty {
                Text("LLM is still generating your roadmap...")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                ForEach(goalRoadmaps, id: \.0.id) { goal, roadmap in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Text("🎯 Goal: \(goal.title)").font(.subheadline).foregroundColor(.gray)
                            Text(countdownText).font(.subheadline).foregroundColor(.blue)
                        }

                        Text("📅 Roadmap").font(.headline)

                        let stepDates: [(step: RoadmapStep, start: Date)] = {
                            var dates: [(RoadmapStep, Date)] = []
                            var current = roadmap.createdAt
                            for step in roadmap.steps {
                                dates.append((step, current))
                                current = Calendar.current.date(byAdding: .day, value: step.durationDays, to: current) ?? current
                            }
                            return dates
                        }()

                        let currentIndex = currentRoadmapStepIndex(for: roadmap)

                        ForEach(Array(stepDates.enumerated()), id: \.element.0.id) { index, pair in
                            let step = pair.0
                            let date = pair.1

                            DisclosureGroup(
                                isExpanded: Binding(
                                    get: {
                                        expandedStepsByGoal[goal.id, default: []].contains(step.id)
                                    },
                                    set: { newValue in
                                        if newValue {
                                            expandedStepsByGoal[goal.id, default: []].insert(step.id)
                                        } else {
                                            expandedStepsByGoal[goal.id, default: []].remove(step.id)
                                        }
                                    }
                                ),
                                content: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("⏱ \(step.durationDays) days").font(.caption)
                                        Text("📦 \(step.toolsOrResources.joined(separator: ", "))").font(.caption)
                                        Text(step.description).font(.caption2).foregroundColor(.gray)
                                    }
                                    .padding(.top, 4)
                                },
                                label: {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(formattedDisplayDate(date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .frame(width: 90, alignment: .leading)
                                        Text("• \(step.title)").bold()

                                        if index == currentIndex {
                                            Text("📍 You are here")
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            )
                        }

                        Divider().padding(.top, 8)
                    }
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
    
    private func computeStepStartDates(for roadmap: Roadmap) -> [(RoadmapStep, Date)] {
        var dates: [(RoadmapStep, Date)] = []
        var currentDate = roadmap.createdAt
        for step in roadmap.steps {
            dates.append((step, currentDate))
            currentDate = Calendar.current.date(byAdding: .day, value: step.durationDays, to: currentDate) ?? currentDate
        }
        return dates
    }


    private func formattedDisplayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }


    private func buildStepViews(goal: Goal, roadmap: Roadmap) -> [some View] {
        var accumulatedDays = 0

        return roadmap.steps.map { step in
            let stepStartDate = Calendar.current.date(byAdding: .day, value: accumulatedDays, to: roadmap.createdAt) ?? roadmap.createdAt
            accumulatedDays += step.durationDays

            return AnyView(
                DisclosureGroup(
                    isExpanded: Binding(
                        get: {
                            expandedStepsByGoal[goal.id, default: []].contains(step.id)
                        },
                        set: { newValue in
                            if newValue {
                                expandedStepsByGoal[goal.id, default: []].insert(step.id)
                            } else {
                                expandedStepsByGoal[goal.id, default: []].remove(step.id)
                            }
                        }
                    ),
                    content: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⏱ \(step.durationDays) days").font(.caption)
                            Text("📦 \(step.toolsOrResources.joined(separator: ", "))").font(.caption)
                            Text(step.description).font(.caption2).foregroundColor(.gray)
                        }
                        .padding(.top, 4)
                    },
                    label: {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(formattedDisplayDate(stepStartDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 90, alignment: .leading)
                            Text("• \(step.title)").bold()
                        }
                    }
                )
            )
        }
    }

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
    
    private func parseDeadline(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
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


    private func loadAllGoalRoadmaps() {
        goalRoadmaps = []  // Clear previous
        expandedStepsByGoal = [:]

        let fileManager = FileManager.default
        let supportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let goalsDir = supportDir.appendingPathComponent("Lunr/Goals")
        let roadmapsDir = supportDir.appendingPathComponent("Lunr/Roadmaps")

        guard let goalFiles = try? fileManager.contentsOfDirectory(at: goalsDir, includingPropertiesForKeys: nil) else {
            print("❌ No goals found.")
            return
        }

        for goalFile in goalFiles {
            guard let goalData = try? Data(contentsOf: goalFile),
                  let goal = try? JSONDecoder().decode(Goal.self, from: goalData) else {
                continue
            }

            let roadmapPath = roadmapsDir.appendingPathComponent("\(goal.id.uuidString).json")
            guard let roadmapData = try? Data(contentsOf: roadmapPath),
                  let roadmap = try? JSONDecoder().decode(Roadmap.self, from: roadmapData) else {
                continue
            }

            goalRoadmaps.append((goal, roadmap))
        }

        print("✅ Loaded \(goalRoadmaps.count) roadmap-goal pairs.")
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
