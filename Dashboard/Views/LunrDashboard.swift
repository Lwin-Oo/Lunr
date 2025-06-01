//
//  LunrDashboard.swift
//  Lunr
//
//  Created by Lwin Oo on 5/19/25.
//

import SwiftUI
import Charts
import Foundation

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
                startFileWatcher(for: selectedDate)
                
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
            
            .onChange(of: selectedDate) {
                fetchUsageData(for: $0)
                startFileWatcher(for: $0)
            }
            
        }
    }
    
    private func startFileWatcher(for date: Date) {
        let fileManager = FileManager.default
        let dir = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Lunr/Screentime")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        let filename = formatter.string(from: date) + ".json"
        let path = dir.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: path.path) else {
            print("❌ File does not exist: \(path.path)")
            return
        }
        
        let fileDescriptor = open(path.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("❌ Failed to open file descriptor.")
            return
        }
        
        fileWatcher?.cancel() // Cancel previous watcher if it exists
        
        fileWatcher = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.main
        )
        
        fileWatcher?.setEventHandler {
            DispatchQueue.main.async {
                print("🔁 Detected change to \(filename). Reloading data...")
                self.fetchUsageData(for: date)
            }
        }
        
        fileWatcher?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileWatcher?.resume()
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
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        print("🔍 Cleaned input: '\(trimmed)'")
        
        // Replace "a" or "an" with 1
        let normalized = trimmed
            .replacingOccurrences(of: #"(^|\s)(a|an)(?=\s)"#, with: "$11", options: .regularExpression)
        
        let regex = try! NSRegularExpression(pattern: #"(\d+)\s*(day|week|month)s?"#, options: [])
        
        if let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)) {
            let valueRange = Range(match.range(at: 1), in: normalized)
            let unitRange = Range(match.range(at: 2), in: normalized)
            
            if let valueStr = valueRange.map({ String(normalized[$0]) }),
               let unit = unitRange.map({ String(normalized[$0]) }),
               let value = Int(valueStr) {
                switch unit {
                case "day": return TimeInterval(value * 86400)
                case "week": return TimeInterval(value * 7 * 86400)
                case "month": return TimeInterval(value * 30 * 86400)
                default:
                    print("❌ Unknown unit: \(unit)")
                    return nil
                }
            }
        }
        
        print("❌ Could not parse duration from '\(normalized)'")
        return nil
    }
    
    
    // MARK: - Header
    
    private var headerSection: some View {
        HeaderSection(
            user: userManager.currentUser,
            goal: userManager.currentUser.flatMap { loadGoal(for: $0) },
            countdownText: countdownText
        )
    }
    
    
    // MARK: - Roadmap
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
    
    // MARK: - MonitoringEngine Toggler
    private var monitoringToggleSection: some View {
        MonitoringToggleSection(
            isMonitoring: isMonitoring,
            toggleMonitoring: toggleMonitoring
        )
    }
    
    
    // MARK: - Calendar
    private var calendarPickerSection: some View {
        CalendarPickerSection(
            selectedDate: $selectedDate,
            loadData: fetchUsageData
        )
    }
    
    
    // MARK: - Summary
    private var summaryCardsSection: some View {
        SummaryCardsSection(
            sessionCount: usageData.count,
            totalTimeFormatted: formattedTotalTime()
        )
    }
    
    // MARK: - Categorized Usage Details
    private var categorizedUsageSection: some View {
        CategorizedUsageSection(sessions: usageData)
    }
    
    // MARK: - Raw Logs
    private var rawLogSection: some View {
        RawLogSection(
            openLogInFinder: openLogInFinder,
            destroyUserData: destroyUserData
        )
    }
    
    // MARK: - Build Step Views
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
    
    
    private func toggleMonitoring() {
        handleMonitoringToggle(
            isMonitoring: &isMonitoring,
            runLogger: runLogger,
            stopLogger: stopLogger
        )
    }
    
    
    
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
    
    
    private func openLogInFinder() {
        openLogFile(for: selectedDate)
    }
    
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M-d-yy"
        return formatter.string(from: date)
    }
    
    
    
    private func formattedTotalTime() -> String {
        let totalSeconds = usageData.map(\.durationSeconds).reduce(0, +)
        return formattedTime(totalSeconds)
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

// MARK: - Helper Functions
func formatDuration(_ d: TimeInterval) -> String {
    let m = Int(d) / 60, h = m / 60, r = m % 60
    return h > 0 ? "\(h)h \(r)m" : "\(r)m"
}

func mapToMainCategory(_ c: String) -> String {
    let l = c.lowercased()
    if l.contains("code") || l.contains("design") || l.contains("writing") || l.contains("productive") {
        return "Productivity"
    } else if l.contains("entertainment") || l.contains("gaming") || l.contains("social") {
        return "Entertainment"
    }
    return "Utils"
}

func colorForMainCategory(_ cat: String) -> Color {
    switch cat {
    case "Productivity": return .blue
    case "Entertainment": return .orange
    case "Utils": return .gray
    default: return .black
    }
}
