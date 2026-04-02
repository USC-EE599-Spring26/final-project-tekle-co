//
//  Survey.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import CareKitStore
import Foundation

enum Survey: String, CaseIterable, Identifiable {
    case onboard = "Onboard"
    case rangeOfMotion = "Range of Motion"

    var id: Self { self }

    func type() -> Surveyable {
        switch self {
        case .onboard:
            Onboard()
        case .rangeOfMotion:
            RangeOfMotion()
        }
    }
}
