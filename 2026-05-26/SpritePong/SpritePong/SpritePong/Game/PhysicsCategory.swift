//
// Created by Joey Jarosz on 5/7/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

/// Bitmask categories used by SpriteKit physics bodies for contact and collision filtering.
struct PhysicsCategory: OptionSet, Sendable {
    let rawValue: UInt32

    static let ball   = PhysicsCategory(rawValue: 1 << 0)
    static let paddle = PhysicsCategory(rawValue: 1 << 1)
    static let wall   = PhysicsCategory(rawValue: 1 << 2)
}
