#if !os(watchOS) && canImport(ResearchKit)

import CareKit
import CareKitUI
import ResearchKit
import UIKit

/// Used with `OCKSurveyTaskViewController` in the course template. This target uses `CareKitTaskView`
/// instead because `OCKSurveyTaskViewController` is not exposed when CareKit is built via SwiftPM
/// without ResearchKitUI linked into the CareKit target (see comment in `CareViewController`).
final class SurveyViewSynchronizer: OCKSurveyTaskViewSynchronizer {

    override func updateView(
        _ view: OCKInstructionsTaskView,
        context: OCKSynchronizationContext<OCKTaskEvents>
    ) {

        super.updateView(view, context: context)

        if let event = context.viewModel.first?.first, event.outcome != nil {
            view.instructionsLabel.isHidden = false
            /*
             TODO: You need to modify this so the instruction label shows
             correctly for each Task/Card.
             Hint - Each event (OCKAnyEvent) has a task. How can you use
             this task to determine what instruction answers should show?
             Look at how the CareViewController differentiates between
             surveys.
             */
        } else {
            view.instructionsLabel.isHidden = true
        }
    }
}

#endif
