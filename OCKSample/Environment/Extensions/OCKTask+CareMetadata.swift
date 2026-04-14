//
//  OCKTask+CareMetadata.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/12/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  OCKTask+CareMetadata.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import Foundation
import CareKitStore

extension OCKTask: CareTask {}

extension OCKHealthKitTask: CareTask {}

extension OCKTask {
    #if !os(watchOS)
    var surveySteps: [SurveyStep]? {
        get {
            guard let value = userInfo?[Constants.surveySteps],
                  let data = value.data(using: .utf8) else {
                return nil
            }
            return try? JSONDecoder().decode([SurveyStep].self, from: data)
        }
        set {
            if userInfo == nil { userInfo = [:] }
            guard let newValue else {
                userInfo?.removeValue(forKey: Constants.surveySteps)
                return
            }
            let data = try? JSONEncoder().encode(newValue)
            userInfo?[Constants.surveySteps] = data.flatMap { String(data: $0, encoding: .utf8) }
        }
    }
    #endif
}
