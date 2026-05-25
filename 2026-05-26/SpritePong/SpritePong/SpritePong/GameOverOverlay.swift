//
// Created by Joey Jarosz on 5/7/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct GameOverOverlay: View {
    let gameState: GameState

    var body: some View {
        VStack {
            Text("Game Over")
                .font(.largeTitle)
                .bold()
            Text("Score: \(gameState.score)")
                .font(.title2)
            Text("Tap to play again")
                .font(.headline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.6))
        .contentShape(.rect)
        .onTapGesture {
            gameState.restart()
        }
    }
}

#Preview {
    GameOverOverlay(gameState: {
        let state = GameState()
        state.score = 7
        state.isGameOver = true
        return state
    }())
}
