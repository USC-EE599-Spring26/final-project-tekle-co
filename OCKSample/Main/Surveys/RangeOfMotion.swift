//
//  RangeOfMotion.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  RangeOfMotion.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
#if canImport(ResearchKit)
import ResearchKit
#if canImport(ResearchKitActiveTask)
import ResearchKitActiveTask
#endif

struct RangeOfMotion: Surveyable {
    static var surveyType: Survey {
        Survey.rangeOfMotion
    }
}

extension RangeOfMotion {
    func createSurvey() -> ORKTask {
        #if canImport(ResearchKitActiveTask)
        let rangeOfMotionOrderedTask = ORKOrderedTask.kneeRangeOfMotionTask(
            withIdentifier: identifier(),
            limbOption: .left,
            intendedUseDescription: nil,
            options: [.excludeConclusion]
        )
        let completionStep = ORKCompletionStep(identifier: "\(identifier()).completion")
        completionStep.title = "All done!"
        completionStep.detailText = "We know the road to recovery can be tough. Keep up the good work!"
        rangeOfMotionOrderedTask.addSteps(from: [completionStep])
        return rangeOfMotionOrderedTask
        #else
        return ORKOrderedTask(identifier: identifier(), steps: [])
        #endif
    }

    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]? {
        #if canImport(ResearchKitActiveTask)
        guard let motionResult = result.results?
            .compactMap({ $0 as? ORKStepResult })
            .compactMap({ $0.results })
            .flatMap({ $0 })
            .compactMap({ $0 as? ORKRangeOfMotionResult })
            .first else {
            assertionFailure("Failed to parse range of motion result")
            return nil
        }
        var range = OCKOutcomeValue(motionResult.range)
        range.kind = #keyPath(ORKRangeOfMotionResult.range)
        return [range]
        #else
        return nil
        #endif
    }
}
#endif
