//
//  CardEnabledEnvironmentKey.swift
//  OCKSample
//
//  Created by Kayal Bhatia on 4/12/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//

//
//  CardEnabledEnvironmentKey.swift
//  OCKSample
//
//  Created by Corey Baker on 3/10/26.
//  Copyright © 2026 Network Reconnaissance Lab. All rights reserved.
//
import SwiftUI

private struct CardEnabledEnvironmentKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue = true
}

extension EnvironmentValues {
    var isCardEnabled: Bool {
        get { self[CardEnabledEnvironmentKey.self] }
        set { self[CardEnabledEnvironmentKey.self] = newValue }
    }
}

extension View {
    func cardEnabled(_ enabled: Bool) -> some View {
        self.environment(\.isCardEnabled, enabled)
    }
}
