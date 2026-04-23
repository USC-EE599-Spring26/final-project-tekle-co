//
//  OCKTask+ResearchKitSwiftUI.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  OCKTask+ResearchKitSwiftUI.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import CareKitStore
import Foundation

extension OCKTask {
    var uiKitSurvey: Survey? {
        get {
            guard let surveyInfo = userInfo?[Constants.uiKitSurvey],
                  let surveyType = Survey(rawValue: surveyInfo) else {
                return nil
            }
            return surveyType
        }
        set {
            if userInfo == nil {
                userInfo = .init()
            }
            userInfo?[Constants.uiKitSurvey] = newValue?.rawValue
        }
    }
}
