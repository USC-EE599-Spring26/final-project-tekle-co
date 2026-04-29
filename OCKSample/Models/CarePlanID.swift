//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    /// Tasks directly related to medication cycle and comedown tracking.
    case medicationManagement
    /// Lifestyle factors (meals, hydration, sleep, exercise, focus) that may influence comedown.
    case lifestyleFactors
}
