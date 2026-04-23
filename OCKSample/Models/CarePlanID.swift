//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/15/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  CarePlanID.swift
//  OCKSample
//
//  Created by Corey Baker on 3/24/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import Foundation

// If you don't remember what an OCKCarePlan is, read the CareKit docs.
enum CarePlanID: String, CaseIterable, Identifiable {
    var id: Self { self }
    case health
    case wellness
    case nutrition
}
