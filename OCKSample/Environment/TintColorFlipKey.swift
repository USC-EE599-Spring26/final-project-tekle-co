//
//  TintColorFlipKey.swift
//  OCKSample
//
//  Created by Corey Baker on 9/26/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import SwiftUI

struct TintColorFlipKey: EnvironmentKey {
    static var defaultValue: UIColor {
        #if os(iOS) || os(visionOS)
        return UIColor {
            $0.userInterfaceStyle == .light
            ? UIColor(#colorLiteral(red: 0.55, green: 0.35, blue: 0.95, alpha: 1))
            : UIColor(#colorLiteral(red: 0.95, green: 0.3, blue: 0.6, alpha: 1))
        }
        #else
        return UIColor(#colorLiteral(red: 0.55, green: 0.35, blue: 0.95, alpha: 1))
        #endif
    }
}

extension EnvironmentValues {
    var tintColorFlip: UIColor {
        self[TintColorFlipKey.self]
    }
}
