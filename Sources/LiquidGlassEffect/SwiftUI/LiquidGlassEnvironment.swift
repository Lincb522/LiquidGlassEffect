//
//  LiquidGlassEnvironment.swift
//  LiquidGlassEffect
//
//  Environment Keys for LiquidGlass
//

import SwiftUI

struct LiquidGlassGroupCoordinatorKey: EnvironmentKey {
    static let defaultValue: LiquidGlassGroupCoordinator? = nil
}

public extension EnvironmentValues {
    var liquidGlassGroupCoordinator: LiquidGlassGroupCoordinator? {
        get { self[LiquidGlassGroupCoordinatorKey.self] }
        set { self[LiquidGlassGroupCoordinatorKey.self] = newValue }
    }
}
