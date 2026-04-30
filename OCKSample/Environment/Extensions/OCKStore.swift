//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//
import Foundation
import Contacts
import CareKit
import CareKitStore
import os.log
import ParseSwift
import ParseCareKit

// swiftlint:disable function_body_length

extension OCKStore {

    func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws -> [OCKContact] {
        let contactIdsToAdd = contacts.compactMap { $0.id }

        // Prepare query to see if contacts are already added
        var query = OCKContactQuery(for: Date())
        query.ids = contactIdsToAdd

        let foundContacts = try await fetchContacts(query: query)

        // Find all missing contacts.
        let contactsNotInStore = contacts.filter { potentialContact -> Bool in
            guard foundContacts.first(where: { $0.id == potentialContact.id }) == nil else {
                return false
            }
            return true
        }

        // Only add if there's a new contact
        guard contactsNotInStore.count > 0 else {
            return []
        }

        let addedContacts = try await addContacts(contactsNotInStore)
        return addedContacts
    }

    @MainActor
    static func getCarePlanUUIDs() async throws -> [CarePlanID: UUID] {
        var results = [CarePlanID: UUID]()
        guard let store = AppDelegateKey.defaultValue?.store else {
            return results
        }
        var query = OCKCarePlanQuery(for: Date())
        query.ids = CarePlanID.allCases.map { $0.rawValue }
        let foundCarePlans = try await store.fetchCarePlans(query: query)
        CarePlanID.allCases.forEach { carePlanID in
            results[carePlanID] = foundCarePlans
                .first(where: { $0.id == carePlanID.rawValue })?.uuid
        }
        return results
    }

    func addCarePlansIfNotPresent(
        _ carePlans: [OCKAnyCarePlan],
        patientUUID: UUID? = nil
    ) async throws {
        let carePlanIdsToAdd = carePlans.compactMap(\.id)
        var query = OCKCarePlanQuery(for: Date())
        query.ids = carePlanIdsToAdd
        let foundCarePlans = try await fetchAnyCarePlans(query: query)
        var carePlanNotInStore = [OCKAnyCarePlan]()
        carePlans.forEach { potentialCarePlan in
            if foundCarePlans.first(where: { $0.id == potentialCarePlan.id }) == nil {
                guard var mutableCarePlan = potentialCarePlan as? OCKCarePlan else {
                    carePlanNotInStore.append(potentialCarePlan)
                    return
                }
                mutableCarePlan.patientUUID = patientUUID
                carePlanNotInStore.append(mutableCarePlan)
            }
        }
        guard !carePlanNotInStore.isEmpty else {
            return
        }
        do {
            _ = try await addAnyCarePlans(carePlanNotInStore)
            Logger.ockStore.info("Added care plans into OCKStore.")
        } catch {
            Logger.ockStore.error("Error adding care plans: \(error.localizedDescription)")
        }
    }

    func populateCarePlans(patientUUID: UUID? = nil) async throws {
        let medicationPlan = OCKCarePlan(
            id: CarePlanID.medicationManagement.rawValue,
            title: "Medication & Comedown Tracking",
            patientUUID: patientUUID
        )
        let lifestylePlan = OCKCarePlan(
            id: CarePlanID.lifestyleFactors.rawValue,
            title: "Lifestyle Factors",
            patientUUID: patientUUID
        )
        try await addCarePlansIfNotPresent(
            [medicationPlan, lifestylePlan],
            patientUUID: patientUUID
        )
    }

    // Adds tasks and contacts into the store
    func populateDefaultCarePlansTasksContacts(
        patientUUID: UUID? = nil,
        startDate: Date = Date()
    ) async throws {

        try await populateCarePlans(patientUUID: patientUUID)
        let carePlanUUIDs = try await Self.getCarePlanUUIDs()
        let medPlanUUID = carePlanUUIDs[.medicationManagement]
        let lifestylePlanUUID = carePlanUUIDs[.lifestyleFactors]

        let thisMorning = Calendar.current.startOfDay(for: startDate)
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let earlyMorning = Calendar.current.date(byAdding: .hour, value: 7, to: aFewDaysAgo)!
        let midMorning = Calendar.current.date(byAdding: .hour, value: 9, to: aFewDaysAgo)!
        let afternoon = Calendar.current.date(byAdding: .hour, value: 15, to: aFewDaysAgo)!

        // =====================================================================
        // MARK: Task 1 — Medication Log (button log, daily at 9am)
        // =====================================================================
        let medLogSchedule = OCKSchedule.dailyAtTime(
            hour: 9, minutes: 0,
            start: midMorning, end: nil,
            text: "Log when you take your medication",
            duration: .allDay
        )
        var medicationLog = OCKTask(
            id: TaskID.medicationLog,
            title: "Medication Log",
            carePlanUUID: medPlanUUID,
            schedule: medLogSchedule
        )
        medicationLog.instructions = "Tap to log when you take your ADHD medication. "
            + "The timestamp helps track your comedown window."
        medicationLog.impactsAdherence = true
        medicationLog.asset = "pills.fill"
        medicationLog.card = .button
        medicationLog.priority = 1

        // =====================================================================
        // MARK: Task 2 — Comedown Severity (custom card, daily at 3pm)
        // =====================================================================
        let comedownSchedule = OCKSchedule.dailyAtTime(
            hour: 15, minutes: 0,
            start: afternoon, end: nil,
            text: "Rate your comedown severity",
            duration: .allDay
        )
        var comedownSeverity = OCKTask(
            id: TaskID.comedownSeverity,
            title: "Comedown Severity",
            carePlanUUID: medPlanUUID,
            schedule: comedownSchedule
        )
        comedownSeverity.instructions = "Rate how intense your brain fog or emotional crash "
            + "feels right now on a scale of 1 (minimal) to 10 (severe)."
        comedownSeverity.impactsAdherence = true
        comedownSeverity.asset = "brain.head.profile.fill"
        comedownSeverity.card = .custom
        comedownSeverity.priority = 2

        // =====================================================================
        // MARK: Task 3 — Meal Timing Log (custom card, 3x/day)
        // =====================================================================
        let breakfastElement = OCKScheduleElement(
            start: Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!,
            end: nil,
            interval: DateComponents(day: 1),
            text: "Breakfast",
            targetValues: [],
            duration: .hours(3)
        )
        let lunchElement = OCKScheduleElement(
            start: Calendar.current.date(byAdding: .hour, value: 12, to: aFewDaysAgo)!,
            end: nil,
            interval: DateComponents(day: 1),
            text: "Lunch",
            targetValues: [],
            duration: .hours(3)
        )
        let dinnerElement = OCKScheduleElement(
            start: Calendar.current.date(byAdding: .hour, value: 18, to: aFewDaysAgo)!,
            end: nil,
            interval: DateComponents(day: 1),
            text: "Dinner",
            targetValues: [],
            duration: .hours(3)
        )
        let mealSchedule = OCKSchedule(
            composing: [breakfastElement, lunchElement, dinnerElement]
        )
        var mealTiming = OCKTask(
            id: TaskID.mealTiming,
            title: "Meal Timing",
            carePlanUUID: lifestylePlanUUID,
            schedule: mealSchedule
        )
        mealTiming.instructions = "Log each meal and when you ate relative to your comedown. "
            + "This helps identify if meal timing affects your crash."
        mealTiming.impactsAdherence = false
        mealTiming.asset = "fork.knife"
        mealTiming.card = .custom
        mealTiming.priority = 4

        // =====================================================================
        // MARK: Task 4 — Exercise (checklist, every other day)
        // =====================================================================
        let exerciseElement = OCKScheduleElement(
            start: earlyMorning,
            end: nil,
            interval: DateComponents(day: 2)
        )
        let exerciseSchedule = OCKSchedule(
            composing: [exerciseElement]
        )
        var exercise = OCKTask(
            id: TaskID.exercise,
            title: "Exercise / Movement",
            carePlanUUID: lifestylePlanUUID,
            schedule: exerciseSchedule
        )
        exercise.instructions = "Check off the types of exercise you did today. "
            + "Movement can significantly affect how your comedown feels."
        exercise.impactsAdherence = true
        exercise.asset = "figure.run"
        exercise.card = .checklist
        exercise.priority = 6

        // =====================================================================
        // MARK: Task 5 — Focus/Stimulus Log (grid, weekdays only)
        // =====================================================================
        var focusElements = [OCKScheduleElement]()
        for dayOffset in 0..<5 {
            var nextWeekday = DateComponents()
            nextWeekday.weekday = 2 + dayOffset // 2=Mon ... 6=Fri
            nextWeekday.hour = 10
            guard let nextDate = Calendar.current.nextDate(
                after: aFewDaysAgo,
                matching: nextWeekday,
                matchingPolicy: .nextTime
            ) else { continue }
            let element = OCKScheduleElement(
                start: nextDate,
                end: nil,
                interval: DateComponents(weekOfYear: 1)
            )
            focusElements.append(element)
        }
        let focusSchedule = OCKSchedule(composing: focusElements)
        var focusStimulus = OCKTask(
            id: TaskID.focusStimulus,
            title: "Focus & Stimulus",
            carePlanUUID: lifestylePlanUUID,
            schedule: focusSchedule
        )
        focusStimulus.instructions = "Select the focus or calming activities you did today. "
            + "Tracks which mental activities correlate with better comedown days."
        focusStimulus.impactsAdherence = true
        focusStimulus.asset = "brain.filled.head.profile"
        focusStimulus.card = .grid
        focusStimulus.priority = 7

        // =====================================================================
        // MARK: Task 6 — ADHD Check-In Survey
        // =====================================================================
        let adhdCheckIn = createADHDCheckInSurveyTask(carePlanUUID: medPlanUUID)

        // =====================================================================
        // Add all tasks
        // =====================================================================
        _ = try await addTasksIfNotPresent(
            [
                medicationLog,
                comedownSeverity,
                mealTiming,
                exercise,
                focusStimulus,
                adhdCheckIn
            ]
        )

        _ = try await addOnboardingTask(medPlanUUID)
        _ = try await addUIKitSurveyTasks(medPlanUUID)

        // =====================================================================
        // MARK: Contacts
        // =====================================================================
        var contact1 = OCKContact(
            id: "drPatel",
            givenName: "Priya",
            familyName: "Patel",
            carePlanUUID: medPlanUUID
        )
        contact1.title = "Psychiatrist"
        contact1.role = "Dr. Patel specializes in adult ADHD medication management."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "drpatel@adhdcare.com")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(310) 555-0142")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(310) 555-0143")]
        contact1.address = {
            let address = OCKPostalAddress(
                street: "1500 San Pablo St",
                city: "Los Angeles",
                state: "CA",
                postalCode: "90033",
                country: "US"
            )
            return address
        }()

        var contact2 = OCKContact(
            id: "sarahCoach",
            givenName: "Sarah",
            familyName: "Kim",
            carePlanUUID: lifestylePlanUUID
        )
        contact2.title = "ADHD Coach"
        contact2.role = "Sarah helps clients build routines and coping strategies for ADHD."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(310) 555-0200")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(310) 555-0201")]
        contact2.address = {
            let address = OCKPostalAddress(
                street: "2025 Wilshire Blvd",
                city: "Los Angeles",
                state: "CA",
                postalCode: "90057",
                country: "US"
            )
            return address
        }()

        _ = try await addContactsIfNotPresent(
            [
                contact1,
                contact2
            ]
        )
    }

    // MARK: - ADHD Check-In Survey

    func createADHDCheckInSurveyTask(carePlanUUID: UUID?) -> OCKTask {
        let taskId = TaskID.adhdCheckIn
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let evening = Calendar.current.date(byAdding: .hour, value: 19, to: aFewDaysAgo)!
        let checkInElement = OCKScheduleElement(
            start: evening,
            end: nil,
            interval: DateComponents(day: 1)
        )
        let checkInSchedule = OCKSchedule(composing: [checkInElement])

        var checkIn = OCKTask(
            id: taskId,
            title: "ADHD Daily Check-In",
            carePlanUUID: carePlanUUID,
            schedule: checkInSchedule
        )

        let moodChoices: [TextChoice] = [
            .init(id: "\(taskId)_mood_0", choiceText: "Great", value: "great"),
            .init(id: "\(taskId)_mood_1", choiceText: "Good", value: "good"),
            .init(id: "\(taskId)_mood_2", choiceText: "Okay", value: "okay"),
            .init(id: "\(taskId)_mood_3", choiceText: "Low", value: "low"),
            .init(id: "\(taskId)_mood_4", choiceText: "Struggling", value: "struggling")
        ]
        let moodQuestion = SurveyQuestion(
            id: "\(taskId)-mood",
            type: .multipleChoice,
            required: true,
            title: "How is your overall mood right now?",
            textChoices: moodChoices,
            choiceSelectionLimit: .single
        )

        let focusQuestion = SurveyQuestion(
            id: "\(taskId)-focus",
            type: .slider,
            required: true,
            title: "How well were you able to focus today?",
            detail: "0 = could not focus at all, 10 = laser-sharp focus",
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let energyQuestion = SurveyQuestion(
            id: "\(taskId)-energy",
            type: .slider,
            required: false,
            title: "Rate your energy level right now",
            detail: "0 = completely drained, 10 = fully energized",
            integerRange: 0...10,
            sliderStepValue: 1
        )

        let step = SurveyStep(
            id: "\(taskId)-step-1",
            questions: [moodQuestion, focusQuestion, energyQuestion],
            asset: "brain.head.profile",
            title: "ADHD Daily Check-In",
            subtitle: "Take a moment to reflect on your day"
        )

        checkIn.impactsAdherence = true
        checkIn.asset = "list.clipboard.fill"
        checkIn.instructions = "A quick daily check-in to track your mood, focus, and energy levels."
        checkIn.card = .survey
        checkIn.priority = 3
        checkIn.surveySteps = [step]

        return checkIn
    }

    // MARK: - Onboarding

    func addOnboardingTask(_ carePlanUUID: UUID?) async throws -> [OCKTask] {
        let onboardSchedule = OCKSchedule.dailyAtTime(
            hour: 0, minutes: 0,
            start: Date(), end: nil,
            text: "Task Due!",
            duration: .allDay
        )
        var onboardTask = OCKTask(
            id: Onboard.identifier(),
            title: "Onboard",
            carePlanUUID: carePlanUUID,
            schedule: onboardSchedule
        )
        onboardTask.instructions = "You'll need to agree to some terms and conditions before we get started!"
        onboardTask.impactsAdherence = false
        onboardTask.card = .uiKitSurvey
        onboardTask.uiKitSurvey = .onboard
        return try await addTasksIfNotPresent([onboardTask])
    }

    // MARK: - UIKit Survey Tasks (Reaction Time ActiveTask)

    func addUIKitSurveyTasks(_ carePlanUUID: UUID?) async throws -> [OCKTask] {
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let nextWeek = Calendar.current.date(
            byAdding: .weekOfYear,
            value: 1,
            to: Date()
        ) ?? Date()
        let nextMonth = Calendar.current.date(
            byAdding: .month,
            value: 1,
            to: thisMorning
        ) ?? thisMorning
        let dailyElement = OCKScheduleElement(
            start: thisMorning,
            end: nextWeek,
            interval: DateComponents(day: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )
        let weeklyElement = OCKScheduleElement(
            start: nextWeek,
            end: nextMonth,
            interval: DateComponents(weekOfYear: 1),
            text: nil,
            targetValues: [],
            duration: .allDay
        )
        let reactionTimeSchedule = OCKSchedule(
            composing: [dailyElement, weeklyElement]
        )
        var reactionTimeTask = OCKTask(
            id: ReactionTime.identifier(),
            title: "Reaction Time Test",
            carePlanUUID: carePlanUUID,
            schedule: reactionTimeSchedule
        )
        reactionTimeTask.instructions = "Measure your cognitive response time to track brain fog levels."
        reactionTimeTask.priority = 5
        reactionTimeTask.asset = "bolt.fill"
        reactionTimeTask.card = .uiKitSurvey
        reactionTimeTask.uiKitSurvey = .reactionTime
        return try await addTasksIfNotPresent([reactionTimeTask])
    }
}
