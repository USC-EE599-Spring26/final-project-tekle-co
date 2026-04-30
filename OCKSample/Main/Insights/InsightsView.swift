//
//  InsightsView.swift
//  OCKSample
//
//  Created by Corey Baker on 4/17/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import CareKit
import CareKitEssentials
import CareKitStore
import CareKitUI
import SwiftUI

struct InsightsView: View {

    @CareStoreFetchRequest(query: query()) private var events
    @State var intervalSelected = 1
    @State var chartInterval = DateInterval()
    @State var period: PeriodComponent = .day
    @State var configurations: [CKEDataSeriesConfiguration] = []
    @State var sortedTaskIDs: [String: Int] = [:]

    var body: some View {
        NavigationStack {
            dateIntervalSegmentView
                .padding()
            ScrollView {
                VStack {
                    // Primary chart: Comedown Severity over time
                    ForEach(orderedEvents) { event in
                        let eventResult = event.result
                        let dataStrategy = determineDataStrategy(for: eventResult.task.id)
                        if eventResult.task.id == TaskID.comedownSeverity {
                            // Comedown severity with medication log overlay
                            let comedownConfig = CKEDataSeriesConfiguration(
                                taskID: TaskID.comedownSeverity,
                                dataStrategy: .mean,
                                mark: .bar,
                                legendTitle: "Comedown Severity",
                                showMarkWhenHighlighted: true,
                                showMeanMark: true,
                                showMedianMark: false,
                                color: .red,
                                gradientStartColor: .red.opacity(0.3)
                            ) { event in
                                event.computeProgress(by: .maxOutcomeValue())
                            }

                            let medicationConfig = CKEDataSeriesConfiguration(
                                taskID: TaskID.medicationLog,
                                dataStrategy: .sum,
                                mark: .bar,
                                legendTitle: "Medication Taken",
                                color: .blue,
                                gradientStartColor: .blue.opacity(0.3),
                                stackingMethod: .unstacked,
                                symbol: .diamond,
                                interpolation: .catmullRom
                            ) { event in
                                event.computeProgress(by: .summingOutcomeValues())
                            }

                            CareKitEssentialChartView(
                                title: "Comedown vs Medication",
                                subtitle: subtitle,
                                dateInterval: $chartInterval,
                                period: $period,
                                configurations: [
                                    comedownConfig,
                                    medicationConfig
                                ]
                            )

                        } else if eventResult.task.id != TaskID.medicationLog
                            && eventResult.task.id != TaskID.comedownSeverity {
                            // Generic chart for other tasks
                            let meanGradientStart = Color(TintColorFlipKey.defaultValue)
                            let meanGradientEnd = Color.accentColor

                            let meanConfiguration = CKEDataSeriesConfiguration(
                                taskID: eventResult.task.id,
                                dataStrategy: dataStrategy,
                                mark: .bar,
                                legendTitle: String(localized: "AVERAGE"),
                                showMarkWhenHighlighted: true,
                                showMeanMark: false,
                                showMedianMark: false,
                                color: meanGradientEnd,
                                gradientStartColor: meanGradientStart
                            ) { event in
                                event.computeProgress(by: .maxOutcomeValue())
                            }

                            let sumConfiguration = CKEDataSeriesConfiguration(
                                taskID: eventResult.task.id,
                                dataStrategy: .sum,
                                mark: .bar,
                                legendTitle: String(localized: "TOTAL"),
                                color: Color(TintColorFlipKey.defaultValue)
                            ) { event in
                                event.computeProgress(by: .maxOutcomeValue())
                            }

                            CareKitEssentialChartView(
                                title: eventResult.title,
                                subtitle: subtitle,
                                dateInterval: $chartInterval,
                                period: $period,
                                configurations: [
                                    meanConfiguration,
                                    sumConfiguration
                                ]
                            )
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                let taskIDs = TaskID.orderedSubjective + TaskID.orderedObjective
                sortedTaskIDs = computeTaskIDOrder(taskIDs: taskIDs)
                events.query.taskIDs = taskIDs
                events.query.dateInterval = eventQueryInterval
                setupChartPropertiesForSegmentSelection(intervalSelected)
            }
#if os(iOS)
            .onChange(of: intervalSelected) { _, intervalSegmentValue in
                setupChartPropertiesForSegmentSelection(intervalSegmentValue)
            }
#else
            .onChange(of: intervalSelected, initial: true) { _, newSegmentValue in
                setupChartPropertiesForSegmentSelection(newSegmentValue)
            }
#endif
        }
    }

    private var orderedEvents: [CareStoreFetchedResult<OCKAnyEvent>] {
        events.latest.sorted(by: { left, right in
            let leftTaskID = left.result.task.id
            let rightTaskID = right.result.task.id

            return sortedTaskIDs[leftTaskID] ?? 0 < sortedTaskIDs[rightTaskID] ?? 0
        })
    }

    private var dateIntervalSegmentView: some View {
        Picker(
            "CHOOSE_DATE_INTERVAL",
            selection: $intervalSelected.animation()
        ) {
            Text("TODAY")
                .tag(0)
            Text("WEEK")
                .tag(1)
            Text("MONTH")
                .tag(2)
            Text("YEAR")
                .tag(3)
        }
        #if !os(watchOS)
        .pickerStyle(.segmented)
        #else
        .pickerStyle(.automatic)
        #endif
    }

    private var subtitle: String {
        switch intervalSelected {
        case 0:
            return String(localized: "TODAY")
        case 1:
            return String(localized: "WEEK")
        case 2:
            return String(localized: "MONTH")
        case 3:
            return String(localized: "YEAR")
        default:
            return String(localized: "WEEK")
        }
    }

    private var eventQueryInterval: DateInterval {
        let interval = Calendar.current.dateInterval(
            of: .weekOfYear,
            for: Date()
        )!
        return interval
    }

    private func determineDataStrategy(for taskID: String) -> CKEDataSeriesConfiguration.DataStrategy {
        switch taskID {
        case TaskID.steps, TaskID.hydration:
            return .max
        default:
            return .mean
        }
    }

    private func setupChartPropertiesForSegmentSelection(_ segmentValue: Int) {
        let now = Date()
        let calendar = Calendar.current
        switch segmentValue {
        case 0:
            let startOfDay = Calendar.current.startOfDay(
                for: now
            )
            let interval = DateInterval(
                start: startOfDay,
                end: now
            )

            period = .day
            chartInterval = interval

        case 1:
            let startDate = calendar.date(
                byAdding: .weekday,
                value: -7,
                to: now
            )!
            period = .week
            chartInterval = DateInterval(start: startDate, end: now)

        case 2:
            let startDate = calendar.date(
                byAdding: .month,
                value: -1,
                to: now
            )!
            period = .month
            chartInterval = DateInterval(start: startDate, end: now)

        case 3:
            let startDate = calendar.date(
                byAdding: .year,
                value: -1,
                to: now
            )!
            period = .month
            chartInterval = DateInterval(start: startDate, end: now)

        default:
            let startDate = calendar.date(
                byAdding: .weekday,
                value: -7,
                to: now
            )!
            period = .week
            chartInterval = DateInterval(start: startDate, end: now)

        }
    }

    private func computeTaskIDOrder(taskIDs: [String]) -> [String: Int] {
        let sortedTaskIDs = taskIDs.enumerated().reduce(into: [String: Int]()) { taskDictionary, task in
            taskDictionary[task.element] = task.offset
        }

        return sortedTaskIDs
    }

    static func query() -> OCKEventQuery {
        let query = OCKEventQuery(dateInterval: .init())
        return query
    }
}

#Preview {
    InsightsView()
        .environment(\.careStore, Utility.createPreviewStore())
        .careKitStyle(Styler())
}
