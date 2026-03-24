//
//  DimensionStyler.swift
//  OCKSample
//
//  Created by Noah Tekle on 3/5/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitUI
import UIKit

struct DimensionStyler: OCKDimensionStyler {

    var cornerRadius: CGFloat {
        16
    }

    var borderWidth: CGFloat {
        1
    }

    var padding: CGFloat {
        12
    }
}
