//
//  ToolProgressTracker.swift
//  Lunr
//
//  Created by Lwin Oo on 6/4/25.
//

import Foundation

final class ToolProgressTracker {
    static let shared = ToolProgressTracker()

    private var progression: RoadmapProgression?
    private var autosaveTimer: Timer?
    private let syncQueue = DispatchQueue(label: "ToolProgressTrackerQueue")

    // MARK: - 🔗 Configure with Bridge (from Progression)
    func configure(with progression: RoadmapProgression) {
        syncQueue.sync {
            self.progression = progression
        }
    }

    // MARK: - 📊 Process Sessions (Updates Progress)
    func processSession(app: String, windowTitle: String, duration: TimeInterval) {
        syncQueue.async {
            guard let progression = self.progression else {
                print("❌ No progression loaded")
                return
            }

            let cleanedApp = self.clean(app)
            let cleanedTitle = self.clean(windowTitle)

            print("\n🔍 Checking session:")
            print("   App           ➤ \(app)")
            print("   Title         ➤ \(windowTitle)")
            print("   Duration      ➤ \(Int(duration))s")
            print("   Clean App     ➤ \(cleanedApp)")
            print("   Clean Title   ➤ \(cleanedTitle)\n")

            var updated = false
            var newEntries: [ToolProgress] = []

            print("📌 Comparing against expected tools from roadmap:")
            for entry in progression.entries {
                let cleanedTool = self.clean(entry.toolName)
                var newEntry = entry

                print("   • Tool: \(entry.toolName) (Step Tool)")
                print("     Cleaned ➤ \(cleanedTool)")

                if cleanedApp.contains(cleanedTool) || cleanedTitle.contains(cleanedTool) {
                    let old = newEntry.progress
                    newEntry.progress += duration
                    let new = newEntry.progress
                    let total = newEntry.requiredHours * 3600

                    print("     ✅ MATCHED")
                    print("     🔄 \(Int(old))s → \(Int(new))s / \(Int(total))s\n")
                    updated = true
                }

                newEntries.append(newEntry)
            }

            if updated {
                self.progression = RoadmapProgression(
                    roadmapId: progression.roadmapId,
                    goalId: progression.goalId,
                    createdAt: progression.createdAt,
                    entries: newEntries
                )
                self.saveProgressionToDisk()
            } else {
                print("❌ No tools matched in this session.\n")
            }
        }
    }

    // MARK: - 🧾 Convert for UI Use (as ToolUsageRequirement)
    func getUpdatedEntries() -> [ToolUsageRequirement] {
        return syncQueue.sync {
            guard let progression = self.progression else { return [] }
            return progression.entries.map {
                ToolUsageRequirement(
                    toolName: $0.toolName,
                    requiredHours: $0.requiredHours,
                    loggedHours: Int($0.progress / 3600)
                )
            }
        }
    }

    // MARK: - 💾 Save to Disk
    private func saveProgressionToDisk() {
        guard let progression = self.progression else { return }

        print("📤 Saving Progression:")
        for entry in progression.entries {
            print("• \(entry.toolName): \(Int(entry.progress))/\(Int(entry.requiredHours * 3600))s")
        }

        let fileManager = FileManager.default
        guard let dir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Lunr/Progressions", isDirectory: true) else {
            print("❌ Could not resolve Progressions directory.")
            return
        }

        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("\(progression.roadmapId.uuidString).json")

        do {
            let data = try JSONEncoder().encode(progression)
            try data.write(to: fileURL)
            print("💾 Progression saved to: \(fileURL.path)\n")
        } catch {
            print("❌ Failed to save progression: \(error)")
        }
    }

    // MARK: - 🧹 Clean Helper
    private func clean(_ str: String) -> String {
        return str
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    // MARK: - 🕒 AutoSave (Optional)
    func startAutoSave(interval: TimeInterval = 300) {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.syncQueue.async {
                self.saveProgressionToDisk()
            }
        }
    }

    func stopAutoSave() {
        autosaveTimer?.invalidate()
        autosaveTimer = nil
    }
}

