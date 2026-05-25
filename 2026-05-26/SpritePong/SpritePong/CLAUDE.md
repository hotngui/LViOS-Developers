# SpritePong

The world's simplest one-player Pong, built for iOS 26. SwiftUI app shell with
all gameplay rendered through a single `SpriteView`-hosted SKScene.

## Architecture

```
SpritePongApp ─▶ ContentView (SwiftUI)
                 ├─ SpriteView(scene: GameScene)
                 │   └─ GameScene (SKScene)
                 │       ├─ paddle (SKShapeNode)
                 │       ├─ ball (SKShapeNode)
                 │       └─ wall edge body (top + left + right; bottom is open)
                 └─ GameOverOverlay (shown when isGameOver)

GameState (@Observable @MainActor)  ◀── shared by ContentView + GameScene
```

`GameState` is the single source of truth for `score` and `isGameOver`. The
SKScene mutates it; SwiftUI observes it and reveals the overlay.

`GameState.resetScene: (() -> Void)?` is filled in by `ContentView.onAppear`
so that `GameState.restart()` can ask the scene to reset its nodes — without
the model having to import SpriteKit.

## Conventions

- One type per file. Files in `SpritePong/Game/` for SpriteKit-side code,
  files at `SpritePong/` root for SwiftUI views.
- All shared state is `@Observable` (never `ObservableObject`).
- Gameplay state pinned to `@MainActor` — matches both SwiftUI and SpriteKit's
  main-thread callback model.
- Test code uses Swift Testing (`import Testing`, `@Test`, `#expect`).
- Visuals are `SKShapeNode` primitives. No assets in `Assets.xcassets`
  beyond the template `AppIcon` / `AccentColor`.

## Build / run

- Target: iOS 26.4, iPhone, portrait only.
- `xcodebuild -scheme SpritePong -destination 'generic/platform=iOS Simulator' build`
  to build.
- `Cmd-U` in Xcode (or `xcodebuild test`) to run `GameStateTests`.

## Gotchas

- The Xcode project uses `PBXFileSystemSynchronizedRootGroup`. New files
  dropped under `SpritePong/SpritePong/` (and subfolders) are auto-added to
  the target — no `.pbxproj` editing required.
- The project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. New types are
  `@MainActor` by default. `GameState` is still annotated explicitly per the
  shared style guide.
- `Self.constant` cannot be used in stored-property initializers in a class —
  use the explicit type name (e.g., `GameScene.ballRadius`).
- The "wall" is a single edge-chain physics body attached to the scene
  itself — no visible node, just three line segments (left/top/right). The
  bottom is intentionally open; ball-below-paddle is detected by polling
  `ball.position.y` in `update(_:)`, not by a sensor edge.
- Score double-counts are debounced via `lastPaddleHitTime` (50ms threshold).
- Ball speed is clamped each frame to keep `restitution = 1` from spiraling
  in corner geometry.
