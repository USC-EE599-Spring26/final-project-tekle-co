//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// TODO: Add care plans specific to your app here.
enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    case health
    case wellness
    case nutrition
}
