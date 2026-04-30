//
//  AppearanceStyler.swift
//  OCKSample
//
//  Created by Noah Tekle on 3/5/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import CareKitUI
import UIKit

struct AppearanceStyler: OCKAppearanceStyler {

    var backgroundColor: UIColor {
        UIColor(#colorLiteral(red: 0.94, green: 0.95, blue: 0.97, alpha: 1))
    }

    var cardShadowOpacity: Float {
        0.15
    }

    var cardShadowRadius: CGFloat {
        6
    }
}
