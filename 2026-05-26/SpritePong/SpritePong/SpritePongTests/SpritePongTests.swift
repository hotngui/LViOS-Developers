//
// Created by Joey Jarosz on 5/7/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import Testing
@testable import SpritePong

@MainActor
struct GameStateTests {
    @Test func initialState() {
        let state = GameState()
        #expect(state.score == 0)
        #expect(state.isGameOver == false)
    }

    @Test func registerPaddleHitIncrementsScore() {
        let state = GameState()
        state.registerPaddleHit()
        #expect(state.score == 1)
        state.registerPaddleHit()
        state.registerPaddleHit()
        #expect(state.score == 3)
    }

    @Test func endGameSetsFlag() {
        let state = GameState()
        state.endGame()
        #expect(state.isGameOver == true)
    }

    @Test func restartZeroesStateAndInvokesResetSceneOnce() {
        let state = GameState()
        state.score = 5
        state.endGame()

        var resetCount = 0
        state.resetScene = { resetCount += 1 }

        state.restart()

        #expect(state.score == 0)
        #expect(state.isGameOver == false)
        #expect(resetCount == 1)
    }
}
