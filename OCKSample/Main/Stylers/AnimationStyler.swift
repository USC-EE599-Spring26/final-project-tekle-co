//
//  AnimationStyler.swift
//  OCKSample
//
//  Created by Noah Tekle on 3/5/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitUI
import SwiftUI

struct AnimationStyler: OCKAnimationStyler {

    var animation: Animation {
            .easeInOut(duration: 0.4)
    }
}
