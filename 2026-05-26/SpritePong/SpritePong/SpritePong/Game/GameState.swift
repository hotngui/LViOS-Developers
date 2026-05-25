//
// Created by Joey Jarosz on 5/7/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import Observation

/// Shared, observable game state. Mutated by `GameScene` and read by SwiftUI views.
@Observable @MainActor
final class GameState {
    var score: Int = 0
    var isGameOver: Bool = false

    /// Set by `ContentView` after the scene is constructed so `restart()` can ask the
    /// scene to reset its nodes. Kept as a closure to avoid a direct reference to
    /// SpriteKit types from this model.
    var resetScene: (() -> Void)?

    func registerPaddleHit() {
        score += 1
    }

    func endGame() {
        isGameOver = true
    }

    func restart() {
        score = 0
        isGameOver = false
        resetScene?()
    }
}
