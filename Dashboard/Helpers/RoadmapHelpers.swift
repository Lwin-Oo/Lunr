//
//  RoadmapHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//
//  This file contains helper functions for calculating start dates of roadmap steps
//  and determining the current active step based on today's date.
//

import Foundation

// MARK: - 📅 Step Start Date Computation

/// Computes the start date for each step in a roadmap based on step durations.
/// - Parameter roadmap: The roadmap containing steps and a creation date.
/// - Returns: An array of tuples containing each step and its corresponding start date.
func computeStepStartDates(for roadmap: Roadmap) -> [(RoadmapStep, Date)] {
    var dates: [(RoadmapStep, Date)] = []
    var currentDate = roadmap.createdAt
    for step in roadmap.steps {
        dates.append((step, currentDate))
        currentDate = Calendar.current.date(byAdding: .day, value: step.durationDays, to: currentDate) ?? currentDate
    }
    return dates
}

// MARK: - 🧭 Current Roadmap Step Index

/// Determines the index of the current active step in the roadmap based on the current date.
/// - Parameter roadmap: The roadmap with its steps and creation date.
/// - Returns: The index of the current roadmap step, or `nil` if none is currently active.
func currentRoadmapStepIndex(for roadmap: Roadmap) -> Int? {
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
