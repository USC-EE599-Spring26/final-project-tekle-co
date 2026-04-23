//
//  Onboard.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitStore
import HealthKit
#if canImport(ResearchKit)
import ResearchKit
import UIKit
#endif

struct Onboard: Surveyable {
    static var surveyType: Survey {
        Survey.onboard
    }
}

#if canImport(ResearchKit)
// swiftlint:disable:next function_body_length
extension Onboard {
    func createSurvey() -> ORKTask {
        let welcomeInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).welcome"
        )
        welcomeInstructionStep.title = "Welcome!"
        welcomeInstructionStep.detailText = """
            Thank you for joining our ADHD mood tracking study. \
            Tap Next to learn more before signing up.
            """
        welcomeInstructionStep.image = UIImage(named: "welcome-image")
        welcomeInstructionStep.imageContentMode = .scaleAspectFill

        let studyOverviewInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).overview"
        )
        studyOverviewInstructionStep.title = "Before You Join"
        studyOverviewInstructionStep.iconImage = UIImage(
            systemName: "checkmark.seal.fill"
        )

        let heartBodyItem = ORKBodyItem(
            text: "The study will ask you to share some of your health data.",
            detailText: nil,
            image: UIImage(systemName: "heart.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        let completeTasksBodyItem = ORKBodyItem(
            text: "You will log your mood, focus, and medication daily.",
            detailText: nil,
            image: UIImage(systemName: "checkmark.circle.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        let signatureBodyItem = ORKBodyItem(
            text: "Before joining, we will ask you to sign an informed consent document.",
            detailText: nil,
            image: UIImage(systemName: "signature"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        let secureDataBodyItem = ORKBodyItem(
            text: "Your data is kept private and secure.",
            detailText: nil,
            image: UIImage(systemName: "lock.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        studyOverviewInstructionStep.bodyItems = [
            heartBodyItem,
            completeTasksBodyItem,
            signatureBodyItem,
            secureDataBodyItem
        ]

        let webViewStep = ORKWebViewStep(
            identifier: "\(identifier()).signatureCapture",
            html: informedConsentHTML
        )
        webViewStep.showSignatureAfterContent = true

        let healthKitTypesToWrite: Set<HKSampleType> = [
            .quantityType(forIdentifier: .bodyMassIndex)!,
            .quantityType(forIdentifier: .activeEnergyBurned)!,
            .categoryType(forIdentifier: .sleepAnalysis)!,
            .workoutType()
        ]
        let healthKitTypesToRead: Set<HKObjectType> = [
            .characteristicType(forIdentifier: .dateOfBirth)!,
            .quantityType(forIdentifier: .stepCount)!,
            .quantityType(forIdentifier: .appleExerciseTime)!,
            .categoryType(forIdentifier: .sleepAnalysis)!,
            .workoutType()
        ]
        let healthKitPermissionType = ORKHealthKitPermissionType(
            sampleTypesToWrite: healthKitTypesToWrite,
            objectTypesToRead: healthKitTypesToRead
        )
        let notificationsPermissionType = ORKNotificationPermissionType(
            authorizationOptions: [.alert, .badge, .sound]
        )
        let motionPermissionType = ORKMotionActivityPermissionType()
        let requestPermissionsStep = ORKRequestPermissionsStep(
            identifier: "\(identifier()).requestPermissionsStep",
            permissionTypes: [
                healthKitPermissionType,
                notificationsPermissionType,
                motionPermissionType
            ]
        )
        requestPermissionsStep.title = "Health Data Request"
        requestPermissionsStep.text = """
            Please review the health data types below and enable \
            sharing to contribute to the study.
            """

        let completionStep = ORKCompletionStep(
            identifier: "\(identifier()).completionStep"
        )
        completionStep.title = "Enrollment Complete"
        completionStep.text = """
            Thank you for enrolling in this study. Your participation \
            will help us better understand ADHD patterns!
            """

        let surveyTask = ORKOrderedTask(
            identifier: identifier(),
            steps: [
                welcomeInstructionStep,
                studyOverviewInstructionStep,
                webViewStep,
                requestPermissionsStep,
                completionStep
            ]
        )
        return surveyTask
    }

    func extractAnswers(_ result: ORKTaskResult) -> [CareKitStore.OCKOutcomeValue]? {
        Task { @MainActor in
            Utility.requestHealthKitPermissions()
        }
        return [OCKOutcomeValue(Date())]
    }
}
#endif
