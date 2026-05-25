# SpritePong — How the app uses SpriteKit

SpritePong is a SwiftUI app whose entire gameplay surface is a single
`SpriteView` rendering a `SKScene`. SwiftUI handles the app shell and the
"Game Over" overlay; SpriteKit handles every pixel and every collision.

## Hosting: SwiftUI ↔ SpriteKit

`ContentView` constructs one `GameScene` (a subclass of `SKScene`) at init
time and embeds it via `SpriteView(scene: scene, options: [.ignoresSiblingOrder])`,
made full-screen with `.ignoresSafeArea()`. The same `SKScene` instance lives
for the lifetime of the app — restarts call `scene.reset()` rather than
allocating a new scene, which avoids a render flash.

A small `@Observable` model (`GameState`, holding `score` and `isGameOver`)
is shared by both sides. `GameScene` writes into it; SwiftUI reads it to
toggle the overlay. The model exposes a `resetScene` closure that
`ContentView.onAppear` wires to `scene.reset()`, so the model can ask the
scene to reset without importing SpriteKit.

## Scene composition

Inside `GameScene.didMove(to:)` we set:
- `physicsWorld.gravity = .zero` and `physicsWorld.contactDelegate = self`
- `anchorPoint = (0, 0)` — bottom-left origin, so "ball below paddle" is
  just `y < 0`
- `scaleMode = .resizeFill` — scene reflows to whatever portrait size
  `SpriteView` gives it
- `backgroundColor = .black`

Three visible-or-invisible bodies are added:

1. **Walls** — *no node*. The scene itself owns one
   `SKPhysicsBody(edgeChainFrom: path)` whose `CGPath` traces left edge → top
   → right edge and stops. The bottom is intentionally absent; that's the
   open lane the ball escapes through on a miss.
2. **Paddle** — a white `SKShapeNode` rectangle with `isDynamic = false`,
   `restitution = 1`, `friction = 0`. It moves only when the player drags.
3. **Ball** — a white `SKShapeNode` circle, `isDynamic = true`, with
   `restitution = 1`, `friction = 0`, `linearDamping = 0`,
   `angularDamping = 0`. An initial impulse in `kickoff()` sends it
   downward with a small horizontal random.

Bodies use a three-category bitmask (`ball`, `paddle`, `wall`) defined in
`PhysicsCategory.swift`. The ball's `collisionBitMask` is `wall | paddle`;
its `contactTestBitMask` is just `paddle` (we only need to *hear about*
paddle contacts).

## Per-frame and contact logic

- **Touch tracking**: `touchesBegan` / `touchesMoved` set `paddle.position.x`
  to the touch's x, clamped to scene bounds. Direct assignment (not
  `SKAction.move`) so the paddle tracks the finger with no input lag.
- **Lose detection**: `update(_:)` polls `ball.position.y < -ballRadius`. If
  true, set `ball.physicsBody?.isDynamic = false` and call
  `gameState.endGame()`. No invisible sensor edge — one compare per frame.
- **Velocity clamp**: `update(_:)` also caps the ball's speed to 600 pt/s,
  guarding against `restitution = 1` corner geometry running away.
- **Scoring + angled bounce**: `didBegin(_:)` filters for the
  `ball | paddle` mask combo, debounces (50 ms) to defeat double-fire on
  edge contacts, then *overrides* the velocity. We compute
  `offset = (ball.x − paddle.x) / (paddle.width / 2)`, clamp to [−1, +1],
  and set the velocity to `(speed · sin θ, speed · cos θ)` with
  `θ = offset × 60°`. This replaces SpriteKit's default mirror-angle
  reflection, giving classic Pong "edge hit = sharp diagonal" feel. Speed is
  preserved with a 220 pt/s floor.

## Reset

`GameScene.reset()` recenters the paddle, recenters the ball, zeroes its
velocity, re-enables `isDynamic`, and reapplies `kickoff()`. No allocations,
instant transition.
