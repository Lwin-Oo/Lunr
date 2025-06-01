//
//  RoadmapHelpers.swift
//  Lunr
//
//  Created by Lwin Oo on 5/31/25.
//

import Foundation

func computeStepStartDates(for roadmap: Roadmap) -> [(RoadmapStep, Date)] {
    var dates: [(RoadmapStep, Date)] = []
    var currentDate = roadmap.createdAt
    for step in roadmap.steps {
        dates.append((step, currentDate))
        currentDate = Calendar.current.date(byAdding: .day, value: step.durationDays, to: currentDate) ?? currentDate
    }
    return dates
}
