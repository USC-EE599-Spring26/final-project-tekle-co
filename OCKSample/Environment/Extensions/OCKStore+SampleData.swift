//
//  OCKStore+SampleData.swift
//  OCKSample
//
//  Created by Corey Baker on 5/6/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation
import os.log

// swiftlint:disable cyclomatic_complexity
extension OCKStore {
    func populateSampleOutcomes(
        startDate: Date
    ) async throws {

        // Prepare previous samples.
        let yesterDay = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Date()
        )!.endOfDay
        guard yesterDay > startDate else {
            throw AppError.errorString("Start date must be before last night")
        }
        let dateInterval = DateInterval(
            start: startDate,
            end: yesterDay
        )
        let eventQuery = OCKEventQuery(
            dateInterval: dateInterval
        )
        let pastEvents = try await fetchEvents(query: eventQuery)
        let pastOutcomes = pastEvents.compactMap { event -> OCKOutcome? in

            let initialRandomDate = randomDate(
                event.scheduleEvent.start,
                end: event.scheduleEvent.end
            )

            switch event.task.id {
            case TaskID.medicationLog:
                let randomBool: Bool = .random()
                guard randomBool else { return nil }
                let outcomeValue = createOutcomeValue(
                    randomBool,
                    createdDate: initialRandomDate
                )
                return addValueToOutcome([outcomeValue], for: event)

            case TaskID.comedownSeverity:
                let randomBool: Bool = .random()
                guard randomBool else { return nil }
                let severity = Int.random(in: 1...10)
                var outcomeValue = createOutcomeValue(
                    severity,
                    createdDate: initialRandomDate
                )
                outcomeValue.kind = "severity"
                return addValueToOutcome([outcomeValue], for: event)

            case TaskID.exercise:
                let randomBool: Bool = .random()
                guard randomBool else { return nil }
                let outcomeValue = createOutcomeValue(
                    randomBool,
                    createdDate: initialRandomDate
                )
                return addValueToOutcome([outcomeValue], for: event)

            case TaskID.mealTiming:
                let randomBool: Bool = .random()
                guard randomBool else { return nil }
                let timingOptions = ["1hr+ before", "30min before", "during", "after", "skipped"]
                let timing = timingOptions.randomElement() ?? "during"
                var outcomeValue = createOutcomeValue(
                    timing,
                    createdDate: initialRandomDate
                )
                outcomeValue.kind = "timingRelativeToComedown"
                return addValueToOutcome([outcomeValue], for: event)

            case TaskID.focusStimulus:
                let randomBool: Bool = .random()
                guard randomBool else { return nil }
                let outcomeValue = createOutcomeValue(
                    randomBool,
                    createdDate: initialRandomDate
                )
                return addValueToOutcome([outcomeValue], for: event)

            default:
                return nil
            }
        }

        do {
            let savedOutcomes = try await addOutcomes(pastOutcomes)
            Logger.ockStore.info("Added sample \(savedOutcomes.count) outcomes to OCKStore!")
        } catch {
            Logger.ockStore.error("Error adding sample outcomes: \(error)")
        }
    }

    #if os(watchOS)
        func populateDefaultCarePlansTasksContacts(startDate: Date = Date()) async throws {}
    #endif

    private func createOutcomeValue(
        _ value: OCKOutcomeValueUnderlyingType,
        createdDate: Date
    ) -> OCKOutcomeValue {
        var outcomeValue = OCKOutcomeValue(
            value
        )
        outcomeValue.createdDate = createdDate
        return outcomeValue
    }

    private func addValueToOutcome(
        _ values: [OCKOutcomeValue],
        for event: OCKEvent<OCKTask, OCKOutcome>
    ) -> OCKOutcome? {

        guard !values.isEmpty else {
            return nil
        }

        guard var outcome = event.outcome else {
            var newOutcome = OCKOutcome(
                taskUUID: event.task.uuid,
                taskOccurrenceIndex: event.scheduleEvent.occurrence,
                values: values
            )

            let effectiveDate = newOutcome
                .sortedOutcomeValuesByRecency()
                .values
                .last?.createdDate ?? event.scheduleEvent.start

            newOutcome.effectiveDate = effectiveDate
            return newOutcome
        }

        outcome.values.append(contentsOf: values)
        let effectiveDate = outcome
            .sortedOutcomeValuesByRecency()
            .values
            .last?.createdDate ?? event.scheduleEvent.start
        outcome.effectiveDate = effectiveDate
        return outcome
    }

    private func randomDate(_ startDate: Date, end endDate: Date) -> Date {
        let timeIntervalRange = startDate.timeIntervalSince1970..<endDate.timeIntervalSince1970
        let randomTimeInterval = TimeInterval.random(in: timeIntervalRange)
        let randomDate = Date(timeIntervalSince1970: randomTimeInterval)
        return randomDate
    }
}
