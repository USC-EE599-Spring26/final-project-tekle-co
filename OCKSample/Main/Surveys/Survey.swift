//
//  Survey.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  Survey.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import Foundation
import CareKitStore

enum Survey: String, CaseIterable, Identifiable {
    var id: Self { self }
    case onboard = "Onboard"
    case rangeOfMotion = "Range of Motion"

    func type() -> any Surveyable {
        switch self {
        case .onboard:
            return Onboard()
        case .rangeOfMotion:
            return RangeOfMotion()
        }
    }
}
