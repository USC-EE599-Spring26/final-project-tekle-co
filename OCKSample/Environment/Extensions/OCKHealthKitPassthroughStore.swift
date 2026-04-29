//
//  OCKHealthKitPassthroughStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitEssentials
import CareKitStore
import HealthKit
import os.log

extension OCKHealthKitPassthroughStore {

    func populateDefaultHealthKitTasks(
        _ patientUUID: UUID? = nil,
        startDate: Date = Date()
    ) async throws {

        let carePlanUUIDs = try await OCKStore.getCarePlanUUIDs()
        let lifestylePlanUUID = carePlanUUIDs[.lifestyleFactors]

        // =====================================================================
        // MARK: HealthKit Task 1 — Hydration (daily water intake)
        // =====================================================================
        let mlUnit = HKUnit.literUnit(with: .milli)
        let hydrationTarget = OCKOutcomeValue(
            2000.0,
            units: mlUnit.unitString
        )
        let hydrationSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: [hydrationTarget]
        )
        var hydration = OCKHealthKitTask(
            id: TaskID.hydration,
            title: "Water Intake",
            carePlanUUID: lifestylePlanUUID,
            schedule: hydrationSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .dietaryWater,
                quantityType: .cumulative,
                unit: mlUnit
            )
        )
        hydration.instructions = "Track your daily water intake. "
            + "Dehydration can worsen ADHD comedown symptoms like brain fog and irritability."
        hydration.asset = "drop.fill"
        hydration.card = .numericProgress
        hydration.priority = 8

        // =====================================================================
        // MARK: HealthKit Task 2 — Resting Heart Rate
        // =====================================================================
        let bpmUnit = HKUnit.count().unitDivided(by: .minute())
        let heartRateTarget = OCKOutcomeValue(
            70.0,
            units: bpmUnit.unitString
        )
        let heartRateSchedule = OCKSchedule.dailyAtTime(
            hour: 7,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: [heartRateTarget]
        )
        var heartRate = OCKHealthKitTask(
            id: TaskID.sleep,
            title: "Resting Heart Rate",
            carePlanUUID: lifestylePlanUUID,
            schedule: heartRateSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .restingHeartRate,
                quantityType: .discrete,
                unit: bpmUnit
            )
        )
        heartRate.instructions = "Your resting heart rate from Apple Watch. "
            + "Elevated heart rate can indicate stress during comedown."
        heartRate.asset = "heart.fill"
        heartRate.card = .labeledValue
        heartRate.priority = 9

        // =====================================================================
        // MARK: Retained — Steps (kept from sample, useful for exercise correlation)
        // =====================================================================
        let countUnit = HKUnit.count()
        let stepTarget = OCKOutcomeValue(
            2000.0,
            units: countUnit.unitString
        )
        let stepSchedule = OCKSchedule.dailyAtTime(
            hour: 8,
            minutes: 0,
            start: startDate,
            end: nil,
            text: nil,
            duration: .allDay,
            targetValues: [stepTarget]
        )
        var steps = OCKHealthKitTask(
            id: TaskID.steps,
            title: "Steps",
            carePlanUUID: lifestylePlanUUID,
            schedule: stepSchedule,
            healthKitLinkage: OCKHealthKitLinkage(
                quantityIdentifier: .stepCount,
                quantityType: .cumulative,
                unit: countUnit
            )
        )
        steps.asset = "figure.walk"
        steps.card = .numericProgress
        steps.priority = 10

        let tasks = [hydration, heartRate, steps]
        _ = try await addTasksIfNotPresent(tasks)
    }
}
