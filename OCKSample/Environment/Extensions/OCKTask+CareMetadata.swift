//
//  OCKTask+CareMetadata.swift
//  OCKSample
//
//  Created by Cursor on 3/24/26.
//

import Foundation
import CareKitStore

private enum CareTaskUserInfoKey {
    static let card = "card"
    static let priority = "priority"
    static let surveySteps = "surveySteps"
}

extension OCKTask: CareTask {
    var card: CareKitCard {
        get {
            guard let value = userInfo?[CareTaskUserInfoKey.card],
                  let card = CareKitCard(rawValue: value) else {
                return .simple
            }
            return card
        }
        set {
            if userInfo == nil { userInfo = [:] }
            userInfo?[CareTaskUserInfoKey.card] = newValue.rawValue
        }
    }

    var priority: Int {
        get {
            guard let value = userInfo?[CareTaskUserInfoKey.priority],
                  let priority = Int(value) else {
                return 100
            }
            return priority
        }
        set {
            if userInfo == nil { userInfo = [:] }
            userInfo?[CareTaskUserInfoKey.priority] = String(newValue)
        }
    }

    var surveySteps: [SurveyStep]? {
        get {
            guard let value = userInfo?[CareTaskUserInfoKey.surveySteps] else {
                return nil
            }
            guard let data = value.data(using: .utf8) else {
                return nil
            }
            return try? JSONDecoder().decode([SurveyStep].self, from: data)
        }
        set {
            if userInfo == nil { userInfo = [:] }
            guard let newValue else {
                userInfo?.removeValue(forKey: CareTaskUserInfoKey.surveySteps)
                return
            }
            let data = try? JSONEncoder().encode(newValue)
            let encodedString = data.flatMap { String(data: $0, encoding: .utf8) }
            userInfo?[CareTaskUserInfoKey.surveySteps] = encodedString
        }
    }
}

extension OCKHealthKitTask: CareTask {
    var card: CareKitCard {
        get {
            guard let value = userInfo?[CareTaskUserInfoKey.card],
                  let card = CareKitCard(rawValue: value) else {
                return .numericProgress
            }
            return card
        }
        set {
            if userInfo == nil { userInfo = [:] }
            userInfo?[CareTaskUserInfoKey.card] = newValue.rawValue
        }
    }

    var priority: Int {
        get {
            guard let value = userInfo?[CareTaskUserInfoKey.priority],
                  let priority = Int(value) else {
                return 100
            }
            return priority
        }
        set {
            if userInfo == nil { userInfo = [:] }
            userInfo?[CareTaskUserInfoKey.priority] = String(newValue)
        }
    }
}
