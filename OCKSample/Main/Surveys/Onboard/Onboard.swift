//
//  Onboard.swift
//  OCKSample
//
//  ADHD Comedown Tracker — Onboarding Flow
//

import CareKitStore
import HealthKit
#if canImport(ResearchKit)
import ResearchKit
import UIKit
#endif

struct Onboard: Surveyable {
    static var surveyType: Survey {
        .onboard
    }
}

#if canImport(ResearchKit)
extension Onboard {
    // swiftlint:disable:next function_body_length
    func createSurvey() -> ORKTask {

        // MARK: Welcome Step
        let welcomeInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).welcome"
        )
        welcomeInstructionStep.title = "Welcome to ComeDown"
        welcomeInstructionStep.detailText = "Take control of your ADHD medication comedown. "
            + "Track what helps, see what doesn't, and find your pattern. "
            + "Tap Next to learn how it works."
        welcomeInstructionStep.image = UIImage(systemName: "brain.head.profile.fill")
        welcomeInstructionStep.imageContentMode = .scaleAspectFit

        // MARK: Overview Step
        let studyOverviewInstructionStep = ORKInstructionStep(
            identifier: "\(identifier()).overview"
        )
        studyOverviewInstructionStep.title = "How ComeDown Works"
        studyOverviewInstructionStep.iconImage = UIImage(systemName: "chart.line.uptrend.xyaxis")

        let trackMedsBodyItem = ORKBodyItem(
            text: "Log when you take your medication and rate your comedown severity.",
            detailText: nil,
            image: UIImage(systemName: "pills.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        let trackLifestyleBodyItem = ORKBodyItem(
            text: "Track meals, hydration, exercise, and focus activities throughout the day.",
            detailText: nil,
            image: UIImage(systemName: "fork.knife"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        let insightsBodyItem = ORKBodyItem(
            text: "See charts comparing your lifestyle choices against comedown severity over time.",
            detailText: nil,
            image: UIImage(systemName: "chart.bar.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        let privacyBodyItem = ORKBodyItem(
            text: "Your data stays private on your device and secure cloud backup.",
            detailText: nil,
            image: UIImage(systemName: "lock.fill"),
            learnMoreItem: nil,
            bodyItemStyle: .image
        )
        studyOverviewInstructionStep.bodyItems = [
            trackMedsBodyItem,
            trackLifestyleBodyItem,
            insightsBodyItem,
            privacyBodyItem
        ]

        // MARK: Consent Signature
        let webViewStep = ORKWebViewStep(
            identifier: "\(identifier()).signatureCapture",
            html: informedConsentHTML
        )
        webViewStep.showSignatureAfterContent = true

        // MARK: HealthKit Permissions
        let healthKitTypesToWrite: Set<HKSampleType> = [
            .quantityType(forIdentifier: .dietaryWater)!,
            .quantityType(forIdentifier: .activeEnergyBurned)!,
            .workoutType()
        ]
        let healthKitTypesToRead: Set<HKObjectType> = [
            .characteristicType(forIdentifier: .dateOfBirth)!,
            .quantityType(forIdentifier: .dietaryWater)!,
            .quantityType(forIdentifier: .stepCount)!,
            .quantityType(forIdentifier: .appleExerciseTime)!,
            .quantityType(forIdentifier: .restingHeartRate)!,
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
        requestPermissionsStep.title = "Health Data Access"
        requestPermissionsStep.text =
            "ComeDown uses health data to automatically track hydration, steps, "
            + "and heart rate alongside your comedown logs. "
            + "Please enable the permissions below for the best experience."

        // MARK: Completion Step
        let completionStep = ORKCompletionStep(
            identifier: "\(identifier()).completionStep"
        )
        completionStep.title = "You're All Set!"
        completionStep.text =
            "Start by logging your medication when you take it today. "
            + "Over time, the Insights tab will reveal which habits help "
            + "you manage your comedown best."

        return ORKOrderedTask(
            identifier: identifier(),
            steps: [
                welcomeInstructionStep,
                studyOverviewInstructionStep,
                webViewStep,
                requestPermissionsStep,
                completionStep
            ]
        )
    }

    func extractAnswers(_: ORKTaskResult) -> [OCKOutcomeValue]? {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Utility.requestHealthKitPermissions()
        }
        return [OCKOutcomeValue(Date())]
    }
}
#endif
