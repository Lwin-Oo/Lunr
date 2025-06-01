//
//  LunrDashboard.swift
//  Lunr
//
//  Created by Lwin Oo on 5/19/25.
//
//  This is the main dashboard view of Lunr OS.
//  It coordinates all sections including usage stats, goal roadmaps,
//  monitoring controls, calendar picker, and raw data access.
//  The dashboard also fetches user reflections and dynamically displays AI-generated encouragement.
//

import SwiftUI
import Charts
import Foundation

// MARK: - 🧠 LunrDashboard Main View
struct LunrDashboard: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var selectedDate = Date()
    @State private var usageData: [DailyAppSession] = []
    @State private var roadmap: [RoadmapStep] = []
    @State private var isMonitoring = MonitoringEngine.shared.isRunning
    @State private var countdownText: String = ""
    @State private var countdownTimer: Timer?
    @State private var stepRequirements: [UUID: [ToolUsageRequirement]] = [:]
    @State private var todayReflection: DailyReflection?
    @State private var encouragementText: String = ""
    @State private var fileWatcher: DispatchSourceFileSystemObject?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        roadmapSection
                        monitoringToggleSection
                        calendarPickerSection
                        summaryCardsSection
                        
                        // ✅ Add space to prevent overlap
                        UsageDonutChartView(sessions: usageData)
                            .padding(.bottom, 32)
                        
                        rawLogSection
                    }
                    .padding()
                }
                .padding(5)
            }
            .navigationTitle("Lunr OS")
            .onAppear {
                fetchUsageData(for: selectedDate)
                fetchGoalRoadmaps()
                isMonitoring = MonitoringEngine.shared.isRunning
                startCountdown()
                
                fileWatcher?.cancel()
                fileWatcher = startFileWatcher(for: selectedDate) {
                    self.fetchUsageData(for: selectedDate)
                }
                
                WeatherManager.shared.fetchWeather { weatherData in
                    guard let weather = weatherData else {
                        DispatchQueue.main.async {
                            encouragementText = "🌤️ Unable to fetch weather."
                        }
                        return
                    }
                    
                    let reflection = MomentumManager.shared.loadReflection(for: Date()) ??
                    DailyReflection(date: Date(), mood: "neutral", topFocus: "Stay focused", smallWin: "")
                    
                    todayReflection = reflection
                    
                    MomentumAI.generateEncouragement(from: reflection, weather: weather) { message in
                        DispatchQueue.main.async {
                            encouragementText = message
                        }
                    }
                }
            }
            
            .onChange(of: selectedDate) { newDate in
                fetchUsageData(for: newDate)
                fileWatcher?.cancel()
                fileWatcher = startFileWatcher(for: newDate) {
                    self.fetchUsageData(for: newDate)
                }
            }
            
        }
    }
    
    // MARK: - ⏳ Countdown Timer
    private func startCountdown() {
        
        countdownTimer?.invalidate()
        
        guard let user = userManager.currentUser,
              let goal = loadGoal(for: user) else {
            countdownText = "No deadline"
            return
        }
        
        print("📅 Parsing deadline: \(goal.targetDeadline)")
        
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
    
    // MARK: - 🧠 Header Section
    private var headerSection: some View {
        HeaderSection(
            user: userManager.currentUser,
            goal: userManager.currentUser.flatMap { loadGoal(for: $0) },
            countdownText: countdownText
        )
    }
    
    
    // MARK: - 🗺️ Roadmap Section
    @State private var goalRoadmaps: [(Goal, Roadmap)] = []
    @State private var expandedStepsByGoal: [UUID: Set<UUID>] = [:]
    private var roadmapSection: some View {
        RoadmapSection(
            goalRoadmaps: $goalRoadmaps,
            expandedStepsByGoal: $expandedStepsByGoal,
            stepRequirements: $stepRequirements,
            todayReflection: $todayReflection,
            encouragementText: encouragementText,
            currentRoadmapStepIndex: currentRoadmapStepIndex,
            formattedDisplayDate: formattedDisplayDate
        )
    }
    
    // MARK: - ⚙️ Monitoring Toggle Section
    private var monitoringToggleSection: some View {
        MonitoringToggleSection(
            isMonitoring: isMonitoring,
            toggleMonitoring: toggleMonitoring
        )
    }
    
    
    // MARK: - 📅 Calendar Section
    private var calendarPickerSection: some View {
        CalendarPickerSection(
            selectedDate: $selectedDate,
            loadData: fetchUsageData
        )
    }
    
    
    // MARK: - 🧾 Summary Cards Section
    private var summaryCardsSection: some View {
        SummaryCardsSection(
            sessionCount: usageData.count,
            totalTimeFormatted: formattedTotalTime()
        )
    }
    
    // MARK: - 📊 Categorized Usage Section
    private var categorizedUsageSection: some View {
        CategorizedUsageSection(sessions: usageData)
    }
    
    // MARK: - 🪵 Raw Log Section
    private var rawLogSection: some View {
        RawLogSection(
            openLogInFinder: openLogInFinder,
            destroyUserData: destroyUserData
        )
    }
    
    // MARK: - 🏗️ Build Roadmap Step Views
    private func buildStepViews(goal: Goal, roadmap: Roadmap) -> some View {
        BuildStepViews(
            goal: goal,
            roadmap: roadmap,
            expandedSteps: Binding(
                get: { expandedStepsByGoal[goal.id] ?? Set<UUID>() },
                set: { newValue in expandedStepsByGoal[goal.id] = newValue }
            ),
            formattedDisplayDate: formattedDisplayDate
        )
    }
    
    // MARK: - 🚀 Monitoring Control
    private func toggleMonitoring() {
        handleMonitoringToggle(
            isMonitoring: &isMonitoring,
            runLogger: runLogger,
            stopLogger: stopLogger
        )
    }
    
    
    // MARK: - 📥 Data Loaders
    private func fetchUsageData(for date: Date) {
        loadData(for: date) { sessions in
            usageData = sessions
        }
    }
    private func fetchGoal(for user: User) {
        if let loadedGoal = loadGoal(for: user) {
            // Do something like assign it to a @State variable
            print("✅ Goal loaded:", loadedGoal.title)
            // Example: self.goal = loadedGoal
        } else {
            print("❌ No goal found")
        }
    }
    private func fetchGoalRoadmaps() {
        loadAllGoalRoadmaps { pairs in
            goalRoadmaps = pairs
            expandedStepsByGoal = [:]
        }
    }
    
    // MARK: - 📂 Log Actions
    private func openLogInFinder() {
        openLogFile(for: selectedDate)
    }
    
    // MARK: - ⏱️ Time Formatting
    private func formattedTotalTime() -> String {
        let totalSeconds = usageData.map(\.durationSeconds).reduce(0, +)
        return formattedTime(totalSeconds)
    }
    
    // MARK: - 🧹 Reset User Data
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
