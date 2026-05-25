//
// Created by Joey Jarosz on 5/7/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var scene: GameScene

    init() {
        let state = GameState()
        let scene = GameScene(size: CGSize(width: 390, height: 844), gameState: state)
        _gameState = State(initialValue: state)
        _scene = State(initialValue: scene)
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .background(.black)
                .ignoresSafeArea()

            if gameState.isGameOver {
                GameOverOverlay(gameState: gameState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: gameState.isGameOver)
        .onAppear {
            gameState.resetScene = { [weak scene] in
                scene?.reset()
            }
        }
    }
}

#Preview {
    ContentView()
}
