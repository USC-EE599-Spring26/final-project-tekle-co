//
//  SurveyViewSynchronizer.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(ResearchKit)
import CareKit
import CareKitStore
import CareKitUI
import ResearchKit
import UIKit
import os.log

final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {
    override func updateView(
        _ view: OCKInstructionsTaskView,
        context: OCKSynchronizationContext<OCKTaskEvents>
    ) {
        super.updateView(view, context: context)

        if let event = context.viewModel.first?.first, event.outcome != nil {
            view.instructionsLabel.isHidden = false

            guard let task = event.task as? OCKTask,
                  let surveyKind = task.uiKitSurvey else {
                view.instructionsLabel.text = "Results recorded."
                return
            }

            switch surveyKind {
            case .rangeOfMotion:
                let range = event.answer(kind: "range")
                view.instructionsLabel.text = "Range: \(Int(range))°"
            case .onboard:
                view.instructionsLabel.text = "Onboarding complete."
            }
        } else {
            view.instructionsLabel.isHidden = true
            view.instructionsLabel.text = nil
        }
    }
}
#endif
