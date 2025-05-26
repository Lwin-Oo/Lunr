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
    @State private var stepRequirements: [UUID: [ToolUsageRequirement]] = [:]
    @State private var todayReflection: DailyReflection?
    @State private var encouragementText: String = ""

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
        VStack(alignment: .leading, spacing: 4) {
            if let user = userManager.currentUser,
               let goal = loadGoal(for: user) {
                Text("👋 Welcome, \(user.name)").font(.title2.bold())

                HStack(spacing: 12) {
                    Text("🎯 Current Goal: \(goal.title)")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(countdownText)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                Text("🔒 No user loaded").font(.subheadline)
            }
        }
    }




    // MARK: - Roadmap

    @State private var goalRoadmaps: [(Goal, Roadmap)] = []
    @State private var expandedStepsByGoal: [UUID: Set<UUID>] = [:]

    private var roadmapSection: some View {
        HStack(alignment: .top, spacing: 24) {
            // Roadmap list (Left Side)
            VStack(alignment: .leading, spacing: 12) {
                if goalRoadmaps.isEmpty {
                    Text("LLM is still generating your roadmap...")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ForEach(goalRoadmaps, id: \.0.id) { goal, roadmap in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🎯 Goal: \(goal.title)").font(.subheadline).foregroundColor(.gray)
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

                                let commitment = Int(goal.dailyTime) ?? 1
                                let requirements = stepRequirements[step.id] ?? {
                                    let generated = ProgressionEngine.generateRequirements(for: step, dailyCommitmentHours: commitment)
                                    stepRequirements[step.id] = generated
                                    return generated
                                }()

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
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("⏱ \(step.durationDays) days").font(.caption)
                                            Text("📦 \(step.toolsOrResources.joined(separator: ", "))").font(.caption)
                                            Text(step.description).font(.caption2).foregroundColor(.gray)

                                            Divider().padding(.vertical, 4)
                                            Text("📈 Required Tool Usage").font(.caption).bold()

                                            ForEach(requirements, id: \.id) { req in
                                                HStack {
                                                    Text("• \(req.toolName)").font(.caption2)
                                                    Spacer()
                                                    Text("🎯 \(req.requiredHours) hrs").font(.caption2).foregroundColor(.gray)
                                                }
                                            }
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
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)

            // Encouragement Card (Right Side)
            if let reflection = todayReflection {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💬 Daily Encouragement").font(.headline)
                    Text(encouragementText)
                        .font(.caption)
                        .padding(10)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(8)
                        .shadow(radius: 1)
                }
                .frame(width: 240)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 Usage Portfolio").font(.headline)

            let grouped = Dictionary(grouping: usageData, by: { $0.classification })
            let formatted = grouped.map { (category, sessions) in
                let total = sessions.map { Double($0.durationSeconds) / 60 }.reduce(0, +)
                let apps = Dictionary(grouping: sessions, by: { $0.app })
                    .map { (name, items) -> (String, String, Double) in
                        let title = items.last?.windowTitle ?? "Unknown"
                        let totalTime = items.map { Double($0.durationSeconds) / 60 }.reduce(0, +)
                        return (name, title, totalTime)
                    }
                    .sorted { $0.2 > $1.2 }
                return (category: category, total: total, apps: apps)
            }
            .sorted { $0.total > $1.total }

            let total = formatted.map(\.total).reduce(0, +)

            HoverPieChart(
                data: formatted,
                total: total,
                size: CGSize(width: 180, height: 180)
            )
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
                        VStack(alignment: .leading, spacing: 6) {
                            Text("⏱ \(step.durationDays) days").font(.caption)
                            Text("📦 \(step.toolsOrResources.joined(separator: ", "))").font(.caption)
                            Text(step.description).font(.caption2).foregroundColor(.gray)
                            
                            let commitmentHours = Int(goal.dailyTime) ?? 1  // fallback to 1 hour if invalid
                            let requirements = ProgressionEngine.generateRequirements(for: step, dailyCommitmentHours: commitmentHours)


                            Divider().padding(.vertical, 4)
                            Text("📈 Required Tool Usage").font(.caption).bold()

                            ForEach(requirements, id: \.id) { req in
                                HStack {
                                    Text("• \(req.toolName)").font(.caption2)
                                    Spacer()
                                    Text("🎯 \(req.requiredHours) hrs").font(.caption2).foregroundColor(.gray)
                                }
                            }
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

// MARK: - PieChart
struct HoverPieChart: View {
    let data: [(category: String, total: Double, apps: [(name: String, windowTitle: String, duration: Double)])]
    let total: Double
    let size: CGSize

    @State private var selectedCategory: String?

    var body: some View {
        HStack(spacing: 20) {
            // Left Label Panel
            VStack(alignment: .leading, spacing: 6) {
                if let selected = selectedCategory,
                   let slice = data.first(where: { $0.category == selected }) {
                    Text("📂 Category: \(slice.category)").font(.caption.bold())
                    ForEach(slice.apps.prefix(5), id: \.name) { app in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("• \(app.name)").font(.caption2.bold())
                            Text("🪟 \(app.windowTitle)").font(.caption2).foregroundColor(.gray)
                            Text("⏱ \(Int(app.duration)) mins").font(.caption2)
                        }
                        .padding(.bottom, 4)
                    }
                    if slice.apps.count > 5 {
                        Text("...").font(.caption2)
                    }
                } else {
                    Text("Tap a slice").font(.caption).foregroundColor(.gray)
                }
            }
            .frame(width: 160)

            // Pie Chart
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2
                var startAngle = -90.0

                for (index, item) in data.enumerated() {
                    let angleSpan = (item.total / max(total, 1)) * 360
                    let endAngle = startAngle + angleSpan

                    let path = Path { path in
                        path.move(to: center)
                        path.addArc(center: center,
                                    radius: radius,
                                    startAngle: .degrees(startAngle),
                                    endAngle: .degrees(endAngle),
                                    clockwise: false)
                        path.closeSubpath()
                    }

                    let isSelected = selectedCategory == item.category
                    let shade = 0.15 + (Double(index) / Double(data.count)) * 0.6
                    let fill = Color(white: isSelected ? 0.2 : shade)

                    context.fill(path, with: .color(fill))
                    context.stroke(path, with: .color(.black), lineWidth: 1)

                    startAngle = endAngle
                }
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let local = value.location
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let dx = local.x - center.x
                        let dy = local.y - center.y
                        let angle = atan2(dy, dx) * 180 / .pi + 90
                        let normalized = angle < 0 ? angle + 360 : angle

                        var runningTotal = 0.0
                        for item in data {
                            let percent = item.total / max(total, 1)
                            let span = percent * 360
                            if normalized >= runningTotal && normalized < runningTotal + span {
                                selectedCategory = item.category
                                return
                            }
                            runningTotal += span
                        }
                    }
            )
        }
    }
}


// MARK: - PieSlice
struct PieSlice: View {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: Double
    let endAngle: Double
    let isHighlighted: Bool

    var body: some View {
        Path { path in
            path.move(to: center)
            path.addArc(center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(endAngle),
                        clockwise: false)
        }
        .fill(isHighlighted ? Color.gray.opacity(0.25) : Color.gray.opacity(0.08))
        .overlay(
            Path { path in
                path.move(to: center)
                path.addArc(center: center,
                            radius: radius,
                            startAngle: .degrees(startAngle),
                            endAngle: .degrees(endAngle),
                            clockwise: false)
            }
            .stroke(Color.black, lineWidth: 1)
        )
    }
}

