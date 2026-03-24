//
//  ColorStyler.swift
//  OCKSample
//
//  Created by Corey Baker on 10/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import CareKitUI
import SwiftUI
import UIKit

struct ColorStyler: OCKColorStyler {
    #if os(iOS) || os(visionOS)
    var label: UIColor {
        FontColorKey.defaultValue
    }
    var tertiaryLabel: UIColor {
		UIColor(Color.accentColor)
    }
    var tint: UIColor {
        UIColor.systemTeal
    }
    var secondaryLabel: UIColor {
        UIColor.systemGray
    }
    var customBackground: UIColor {
        UIColor.systemGroupedBackground
    }
    #endif
}
