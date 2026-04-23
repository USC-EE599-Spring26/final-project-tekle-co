//
//  Surveyable.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  Surveyable.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import Foundation
import CareKitStore
#if canImport(ResearchKit)
import ResearchKit
#endif

protocol Surveyable {
    static var surveyType: Survey { get }
    static func identifier() -> String
    #if canImport(ResearchKit)
    func createSurvey() -> ORKTask
    func extractAnswers(_ result: ORKTaskResult) -> [OCKOutcomeValue]?
    #endif
}

extension Surveyable {
    static func identifier() -> String {
        surveyType.rawValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func identifier() -> String {
        Self.identifier()
    }
}
