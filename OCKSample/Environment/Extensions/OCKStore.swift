//
//  OCKStore.swift
//  OCKSample
//
//  Created by Corey Baker on 1/5/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitEssentials
import CareKitStore
import Contacts
import os.log
import ParseSwift
import ParseCareKit
import CareKit

extension OCKStore {

    func addContactsIfNotPresent(_ contacts: [OCKContact]) async throws -> [OCKContact] {
        let contactIdsToAdd = contacts.compactMap { $0.id }

        // Prepare query to see if contacts are already added
        var query = OCKContactQuery(for: Date())
        query.ids = contactIdsToAdd

        let foundContacts = try await fetchContacts(query: query)

        // Find all missing tasks.
        let contactsNotInStore = contacts.filter { potentialContact -> Bool in
            guard foundContacts.first(where: { $0.id == potentialContact.id }) == nil else {
                return false
            }
            return true
        }

        // Only add if there's a new task
        guard contactsNotInStore.count > 0 else {
            return []
        }

        let addedContacts = try await addContacts(contactsNotInStore)
        return addedContacts
    }

    // Adds tasks and contacts into the store
    func populateDefaultCarePlansTasksContacts(
		startDate: Date = Date()
	) async throws {

        let thisMorning = Calendar.current.startOfDay(for: startDate)
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let afterLunch = Calendar.current.date(byAdding: .hour, value: 14, to: aFewDaysAgo)!

        let schedule = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: beforeBreakfast,
                    end: nil,
                    interval: DateComponents(day: 1)
                ),
                OCKScheduleElement(
                    start: afterLunch,
                    end: nil,
                    interval: DateComponents(day: 2)
                )
            ]
        )

        var doxylamine = OCKTask(
            id: TaskID.doxylamine,
            title: String(localized: "TAKE_DOXYLAMINE"),
            carePlanUUID: nil,
            schedule: schedule
        )
        doxylamine.instructions = String(localized: "DOXYLAMINE_INSTRUCTIONS")
        doxylamine.asset = "pills.fill"
        doxylamine.card = .checklist
        doxylamine.priority = 2

        let nauseaSchedule = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: beforeBreakfast,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: String(localized: "ANYTIME_DURING_DAY"),
                    targetValues: [],
                    duration: .allDay
                )
            ]
        )

        var nausea = OCKTask(
            id: TaskID.nausea,
            title: String(localized: "TRACK_NAUSEA"),
            carePlanUUID: nil,
            schedule: nauseaSchedule
        )
        nausea.impactsAdherence = false
        nausea.instructions = String(localized: "NAUSEA_INSTRUCTIONS")
        nausea.asset = "bed.double"

        let kegelElement = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(day: 2)
        )
        let kegelSchedule = OCKSchedule(
            composing: [kegelElement]
        )
        var kegels = OCKTask(
            id: TaskID.kegels,
            title: String(localized: "KEGEL_EXERCISES"),
            carePlanUUID: nil,
            schedule: kegelSchedule
        )
        kegels.impactsAdherence = true
        kegels.instructions = String(localized: "KEGEL_INSTRUCTIONS")
        kegels.card = .simple
        kegels.priority = 3

        let stretchElement = OCKScheduleElement(
            start: beforeBreakfast,
            end: nil,
            interval: DateComponents(day: 1)
        )
        let stretchSchedule = OCKSchedule(
            composing: [stretchElement]
        )
        var stretch = OCKTask(
            id: TaskID.stretch,
            title: String(localized: "STRETCH"),
            carePlanUUID: nil,
            schedule: stretchSchedule
        )
        stretch.impactsAdherence = true
        stretch.asset = "figure.walk"
        stretch.card = .simple
        stretch.priority = 5

        var medication = OCKTask(
            id: TaskID.medication,
            title: String("Take Methylphenidate"),
            carePlanUUID: nil,
            schedule: schedule
        )
        medication.instructions = String("Take orally twice a day with food")
        medication.asset = "pills.fill"
        medication.card = .checklist
        medication.priority = 7

        let cognitiveLapseLoggerSchedule = OCKSchedule(
            composing: [
                OCKScheduleElement(
                    start: beforeBreakfast,
                    end: nil,
                    interval: DateComponents(day: 1),
                    text: String(localized: "ANYTIME_DURING_DAY"),
                    targetValues: [],
                    duration: .allDay
                )
            ]
        )

        var cognitiveLapseLogger = OCKTask(
            id: TaskID.cognitiveLapseLogger,
            title: String("Track Cognitive Lapse"),
            carePlanUUID: nil,
            schedule: cognitiveLapseLoggerSchedule
        )
        cognitiveLapseLogger.impactsAdherence = false
        cognitiveLapseLogger.instructions = String("When you start feeling brain fog, press")
        cognitiveLapseLogger.asset = "brain.head.profile"
        cognitiveLapseLogger.card = .button
        cognitiveLapseLogger.priority = 8

        #if !os(watchOS)
        let checkIn = createCheckInSurveyTask(carePlanUUID: nil)
        let qualityOfLife = createQualityOfLifeSurveyTask(carePlanUUID: nil)
        let rangeOfMotion = createRangeOfMotionTask(carePlanUUID: nil)
        _ = try await addTasksIfNotPresent(
            [
                checkIn,
                qualityOfLife,
                nausea,
                doxylamine,
                kegels,
                rangeOfMotion,
                stretch,
                medication,
                cognitiveLapseLogger
            ]
        )
        #else
        _ = try await addTasksIfNotPresent(
            [
                nausea,
                doxylamine,
                kegels,
                stretch,
                medication,
                cognitiveLapseLogger
            ]
        )
        #endif

//        _ = try await addTasksIfNotPresent(
//            [
//                medication,
//                cognitiveLapseLogger
////                nausea,
////                doxylamine,
////                kegels,
////                stretch
//            ]
//        )

        var contact1 = OCKContact(
            id: "jane",
            givenName: "Jane",
            familyName: "Daniels",
            carePlanUUID: nil
        )
        contact1.title = "Family Practice Doctor"
        contact1.role = "Dr. Daniels is a family practice doctor with 8 years of experience."
        contact1.emailAddresses = [OCKLabeledValue(label: CNLabelEmailiCloud, value: "janedaniels@uky.edu")]
        contact1.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 257-2000")]
        contact1.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 357-2040")]
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
            id: "matthew",
            givenName: "Matthew",
            familyName: "Reiff",
            carePlanUUID: nil
        )
        contact2.title = "OBGYN"
        contact2.role = "Dr. Reiff is an OBGYN with 13 years of experience."
        contact2.phoneNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 257-1000")]
        contact2.messagingNumbers = [OCKLabeledValue(label: CNLabelWork, value: "(800) 257-1234")]
        contact2.address = {
			let address = OCKPostalAddress(
				street: "1500 San Pablo St",
				city: "Los Angeles",
				state: "CA",
				postalCode: "90033",
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

    #if !os(watchOS)
    func createQualityOfLifeSurveyTask(carePlanUUID: UUID?) -> OCKTask {
        let taskId = TaskID.qualityOfLife
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1))
        ])
        let choices: [TextChoice] = [
            .init(id: "\(taskId)_0", choiceText: String(localized: "ANSWER_YES"), value: "Yes"),
            .init(id: "\(taskId)_1", choiceText: String(localized: "ANSWER_NO"), value: "No")
        ]
        let questionOne = SurveyQuestion(
            id: "\(taskId)-managing-time",
            type: .multipleChoice,
            required: true,
            title: String(localized: "QUALITY_OF_LIFE_TIME"),
            textChoices: choices,
            choiceSelectionLimit: .single
        )
        let questionTwo = SurveyQuestion(
            id: taskId,
            type: .slider,
            required: false,
            title: String(localized: "QUALITY_OF_LIFE_STRESS"),
            detail: String(localized: "QUALITY_OF_LIFE_STRESS_DETAIL"),
            integerRange: 0...10,
            sliderStepValue: 1
        )
        let stepOne = SurveyStep(id: "\(taskId)-step-1", questions: [questionOne, questionTwo])
        var task = OCKTask(
            id: taskId,
            title: String(localized: "QUALITY_OF_LIFE"),
            carePlanUUID: carePlanUUID,
            schedule: schedule
        )
        task.impactsAdherence = true
        task.asset = "brain.head.profile"
        task.card = .survey
        task.priority = 1
        task.surveySteps = [stepOne]
        return task
    }

    func createCheckInSurveyTask(carePlanUUID: UUID?) -> OCKTask {
        let taskId = TaskID.checkIn
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let beforeBreakfast = Calendar.current.date(byAdding: .hour, value: 8, to: aFewDaysAgo)!
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(start: beforeBreakfast, end: nil, interval: DateComponents(day: 1))
        ])
        let choices: [TextChoice] = [
            .init(id: "\(taskId)_0", choiceText: String(localized: "CHECK_IN_LOW"), value: "Low"),
            .init(id: "\(taskId)_1", choiceText: String(localized: "CHECK_IN_MEDIUM"), value: "Medium"),
            .init(id: "\(taskId)_2", choiceText: String(localized: "CHECK_IN_HIGH"), value: "High")
        ]
        let questionOne = SurveyQuestion(
            id: "\(taskId)-energy",
            type: .multipleChoice,
            required: true,
            title: String(localized: "CHECK_IN_ENERGY"),
            textChoices: choices,
            choiceSelectionLimit: .single
        )
        let questionTwo = SurveyQuestion(
            id: "\(taskId)-pain",
            type: .slider,
            required: false,
            title: String(localized: "CHECK_IN_PAIN"),
            detail: String(localized: "CHECK_IN_PAIN_DETAIL"),
            integerRange: 0...10,
            sliderStepValue: 1
        )
        let stepOne = SurveyStep(id: "\(taskId)-step-1", questions: [questionOne, questionTwo])
        var task = OCKTask(
            id: taskId,
            title: String(localized: "CHECK_IN_TITLE"),
            carePlanUUID: carePlanUUID,
            schedule: schedule
        )
        task.impactsAdherence = true
        task.asset = "list.bullet.clipboard"
        task.card = .survey
        task.priority = 0
        task.surveySteps = [stepOne]
        return task
    }

    func createRangeOfMotionTask(carePlanUUID: UUID?) -> OCKTask {
        let taskId = TaskID.rangeOfMotion
        let thisMorning = Calendar.current.startOfDay(for: Date())
        let aFewDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: thisMorning)!
        let morningSession = Calendar.current.date(byAdding: .hour, value: 9, to: aFewDaysAgo)!
        let schedule = OCKSchedule(composing: [
            OCKScheduleElement(
                start: morningSession,
                end: nil,
                interval: DateComponents(day: 1),
                text: String(localized: "RANGE_OF_MOTION_SCHEDULE_TEXT")
            )
        ])
        var task = OCKTask(
            id: taskId,
            title: String(localized: "RANGE_OF_MOTION_TITLE"),
            carePlanUUID: carePlanUUID,
            schedule: schedule
        )
        task.impactsAdherence = true
        task.instructions = String(localized: "RANGE_OF_MOTION_INSTRUCTIONS")
        task.asset = "figure.strengthtraining.functional"
        task.card = .custom
        task.priority = 4
        return task
    }
    #endif
}
