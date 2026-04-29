//
//  ReactionTime.swift
//  OCKSample
//
//  Created for ADHD Comedown Tracker.
//

import CareKitStore
#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)
import ResearchKit
import ResearchKitActiveTask
import AudioToolbox
#endif

struct ReactionTime: Surveyable {
    static var surveyType: Survey {
        .reactionTime
    }
}

#if canImport(ResearchKit) && canImport(ResearchKitActiveTask)
extension ReactionTime {
    func createSurvey() -> ORKTask {
        let reactionTimeTask = ORKOrderedTask.reactionTime(
            withIdentifier: identifier(),
            intendedUseDescription: "This test measures how quickly you can respond to a visual stimulus. "
                + "Faster reaction times may indicate less brain fog.",
            maximumStimulusInterval: 10,
            minimumStimulusInterval: 4,
            thresholdAcceleration: 0.5,
            numberOfAttempts: 3,
            timeout: 3,
            successSound: 0,
            timeoutSound: 0,
            failureSound: UInt32(kSystemSoundID_Vibrate),
            options: [.excludeConclusion]
        )
        let completionStep = ORKCompletionStep(identifier: "\(identifier()).completion")
        completionStep.title = "Test Complete"
        completionStep.detailText = "Your reaction time has been recorded. "
            + "Compare your results over time in the Insights tab."
        reactionTimeTask.addSteps(from: [completionStep])
        return reactionTimeTask
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        guard let reactionTimeResults = result.results?
            .compactMap({ $0 as? ORKStepResult })
            .compactMap(\.results)
            .flatMap({ $0 })
            .compactMap({ $0 as? ORKReactionTimeResult }) else {
            return nil
        }

        // Calculate average reaction time from all attempts
        let timestamps = reactionTimeResults.compactMap { $0.timestamp }
        guard !timestamps.isEmpty else {
            return nil
        }
        let averageTime = timestamps.reduce(0.0, +) / Double(timestamps.count)
        var reactionTimeValue = OCKOutcomeValue(averageTime)
        reactionTimeValue.kind = "reactionTime"
        return [reactionTimeValue]
    }
}
#endif
