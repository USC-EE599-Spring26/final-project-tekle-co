//
//  TaskID.swift
//  OCKSample
//
//  Created by Corey Baker on 4/14/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum TaskID {
    // MARK: - Medication Management care plan tasks
    /// User logs when they took ADHD medication (timestamp matters for comedown window).
    static let medicationLog = "medicationLog"
    /// Dependent variable: user rates comedown severity 1–10.
    static let comedownSeverity = "comedownSeverity"
    /// ResearchKit SwiftUI survey — daily ADHD check-in (mood, energy, focus, irritability).
    static let adhdCheckIn = "adhdCheckIn"
    /// ResearchKit ActiveTask — reaction time test to measure cognitive fog.
    static let reactionTime = "reactionTime"

    // MARK: - Lifestyle Factors care plan tasks
    /// User logs meal timing relative to comedown (3x/day: breakfast, lunch, dinner).
    static let mealTiming = "mealTiming"
    /// HealthKit task — daily water intake in mL.
    static let hydration = "hydration"
    /// HealthKit task — sleep analysis (hours slept).
    static let sleep = "sleep"
    /// Checklist of exercise types done that day (every other day schedule).
    static let exercise = "exercise"
    /// Grid of focus/stimulus activities (weekdays only schedule).
    static let focusStimulus = "focusStimulus"

    // MARK: - Retained sample tasks (kept for compatibility with HealthKit sample code)
    static let steps = "steps"

    // MARK: - Ordering for display and charts
    static var ordered: [String] {
        orderedObjective + orderedSubjective
    }

    static var orderedObjective: [String] {
        [Self.steps, Self.hydration, Self.sleep]
    }

    static var orderedSubjective: [String] {
        [
            Self.medicationLog,
            Self.comedownSeverity,
            Self.mealTiming,
            Self.exercise,
            Self.focusStimulus,
            Self.adhdCheckIn
        ]
    }

    static var orderedWatchOS: [String] {
        [Self.medicationLog, Self.exercise]
    }
}
