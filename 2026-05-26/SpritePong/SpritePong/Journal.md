# SpritePong — A Project Journal

## The Big Picture

Imagine you're hanging out at a coffee shop and a friend asks "hey, what's the
absolute simplest game you could build that still feels like a real game?"
That's SpritePong. It's Pong, but with one paddle, three walls, and a bouncing
ball. You drag your finger to move the paddle. You miss the ball, it's game
over, tap to play again. That's it. That's the whole app.

Why bother? Because "simple" is a great way to learn the bones of a tool —
in this case, the bones of `SpriteView`, which is SwiftUI's bridge to
SpriteKit. There's no clever AI, no asset pipeline, no high-score persistence.
Just the minimum viable bouncing physics required to feel like a game.

## Architecture Deep Dive

The app has three actors and one stage.

- **Stage**: `ContentView` — a SwiftUI view that owns a single `SpriteView`
  filling the screen. Think of it as the stadium. It also pops up a "Game
  Over" sign when the ball escapes.
- **Actor 1**: `GameScene` — the SpriteKit scene that holds the paddle, the
  ball, and the wall edges. Think of it as the field plus the physics-savvy
  referee. It watches what happens, calls plays, and tells the scoreboard
  when something happened.
- **Actor 2**: `GameState` — an `@Observable` model with `score` and
  `isGameOver`. Think of it as the scoreboard *and* the announcer. It doesn't
  know about physics or pixels; it just tracks the truth and SwiftUI listens.
- **Actor 3**: `GameOverOverlay` — a separate SwiftUI view that fades in
  when `isGameOver` flips. Think of it as the giant "GAME OVER" jumbotron.

The communication is one-way and clean:

```
GameScene ──reads & writes──▶ GameState ──reads──▶ ContentView / Overlay
```

Plus one callback going the other direction so the model can ask the scene
to reset:

```
GameState.resetScene = { scene.reset() }   // wired in ContentView.onAppear
```

This split is doing real work. `GameState` doesn't import SpriteKit —
nothing about the model knows what an `SKPhysicsBody` is — which is what
lets it be tested with Swift Testing in milliseconds, no simulator required.

The "wall" is sneaky. There's no wall *node*. The scene itself owns a single
edge-chain physics body that traces left edge → top → right edge and stops.
The bottom is just *missing*, which is what creates the lose condition: a
ball that falls past the paddle eventually has no wall to hit and just leaves.
We detect it via `if ball.position.y < -ballRadius` in the per-frame
`update(_:)` callback. No invisible sensor node, no extra physics category,
no contact-bitmask arithmetic to get wrong. Just one compare per frame.

## The Codebase Map

```
SpritePong/                         ← Xcode project root
├── CLAUDE.md                       ← terse project memory (for Claude)
├── Journal.md                      ← this file (the fun version)
├── SpritePong/
│   ├── SpritePongApp.swift         ← @main, untouched template
│   ├── ContentView.swift           ← SwiftUI host for the SKScene + overlay
│   ├── GameOverOverlay.swift       ← the jumbotron
│   ├── Game/
│   │   ├── GameState.swift         ← @Observable model (score, isGameOver)
│   │   ├── GameScene.swift         ← SKScene: paddle, ball, walls, contacts
│   │   └── PhysicsCategory.swift   ← OptionSet of bitmasks
│   └── Assets.xcassets             ← AppIcon + AccentColor only
├── SpritePongTests/
│   └── SpritePongTests.swift       ← Swift Testing GameStateTests
└── SpritePongUITests/              ← template, untouched
```

Mental model: SwiftUI side at the root, SpriteKit side under `Game/`. One
type per file. The folder boundary doubles as an "import SpriteKit lives
here" boundary.

## Tech Stack & Why

- **iOS 26.4 / Swift 6** — newest tools. The default-MainActor isolation in
  Swift 6 is genuinely nice for a game like this where everything happens on
  the main thread anyway.
- **SwiftUI for chrome, SpriteKit for the field** — SwiftUI is great for
  the overlay and lifecycle but bad at sub-frame physics. SpriteKit is
  built for sub-frame physics. `SpriteView` lets us mix them without a
  `UIViewRepresentable`. Right tool, right place.
- **`@Observable` not `ObservableObject`** — `@Observable` (the macro
  introduced for the new Observation framework) is the modern path; SwiftUI
  re-renders only the views that actually read the changed property,
  instead of every view that observes the object. Faster, simpler.
- **`SKShapeNode` for the paddle and ball** — could have used a small white
  PNG and an `SKSpriteNode`. Didn't. Pure shape nodes mean zero asset work
  and the visual is "rectangle, circle" — anything fancier would just be
  decoration on top.
- **Swift Testing over XCTest** — the test target was already templated for
  Swift Testing; `@Test` + `#expect` is enough. No XCTestCase boilerplate,
  no `XCTAssertEqual` chants.
- **No third-party dependencies** — none needed.

## The Journey

### Decision: wall vs AI opponent

The first big call was whether the "other side" should be a paddle (with
some AI) or just a wall. I went with a wall. Two reasons: (1) "simplest"
was the brief, and a wall is genuinely simpler, and (2) a single-paddle AI
opponent is one of those things that's *deceptively* hard to tune — too
good and the player can't win; too bad and there's no challenge. A wall is
honest. The challenge is purely "don't miss." Done.

### Decision: polling for the lose condition vs a sensor edge

The other natural design here is to put an invisible "loseZone" edge body
across the bottom of the scene, give it a category bitmask, and react in
`didBegin(_:)`. That works. It's also one more thing to misconfigure —
forget to set the `contactTestBitMask` correctly and you'll silently never
fire a game-over.

So instead: the scene's `update(_:)` checks `ball.position.y < -ballRadius`
once per frame. One arithmetic compare. Always works. Cannot be silently
broken by a wrong bitmask. The win is small but it's pure: fewer moving
parts.

### War story: the `Self.constant` trap

First build, this innocent-looking line failed:
```swift
private let ball = SKShapeNode(circleOfRadius: Self.ballRadius)
```
Error: *"Covariant 'Self' type cannot be referenced from a stored property
initializer."* Translation: in a class, `Self` in a stored-property
initializer is too dynamic — a subclass could change what `Self` resolves
to, and Swift refuses to commit. The fix is just to spell out the class
name: `GameScene.ballRadius`. The class is `final` so this isn't actually
ambiguous in practice, but the compiler still enforces the rule. Lesson:
in classes, use the explicit type name in stored-property initializers. In
structs or enums, `Self` is fine.

### War story: the SourceKit "stale-type" mirage

Right after creating new files like `PhysicsCategory.swift` and
`GameState.swift`, the editor lit up with "Cannot find type 'GameState' in
scope" diagnostics from SourceKit-LSP. Looked alarming — but
`xcodebuild build` compiled cleanly. The synchronized group (a
`PBXFileSystemSynchronizedRootGroup`, which is the modern Xcode way of
auto-including files-on-disk into the target) had picked up the new files;
the language server just hadn't reindexed yet. Lesson: when SourceKit and
the build disagree, trust the build.

### Decision: keep one scene, expose `reset()`

Easy alternative: when the user taps "play again," construct a fresh
`GameScene` and rebind it on the `SpriteView`. Tempting because it's more
"functional." Rejected: scene re-binding on `SpriteView` is unreliable in
practice and produces a brief visual flash. Instead `GameState.restart()`
calls a `resetScene` closure which calls `scene.reset()` — repositions the
nodes, zeros velocities, reapplies the kickoff impulse, done. Instant, no
flicker, no allocations.

### Decision: angular paddle deflection (the "feel" upgrade)

The first playable build relied on SpriteKit's automatic
`restitution = 1` reflection — every paddle hit bounced at the mirror angle
of approach. Technically correct, atmospherically dead. Real Pong (and every
brick-breaker since) cheats: where you hit the paddle determines where the
ball goes, regardless of incoming angle. Center hit = nearly straight up.
Edge hit = sharp diagonal.

The implementation is a four-line override inside `didBegin(_:)`:
compute `offset = (ball.x − paddle.x) / (paddle.width / 2)` clamped to
[−1, +1], multiply by `maxBounceAngle` (60°), and set the ball's velocity to
`(speed · sin θ, speed · cos θ)`. Speed is preserved with a `minBallSpeed`
floor of 220 pt/s so a slow drift into the paddle doesn't produce a slow
drift away from it.

Why override velocity instead of, say, applying an impulse? Impulses
*add* to the existing velocity — and the existing velocity is whatever
SpriteKit's auto-reflection just produced. Setting the velocity directly
ignores that and gives us a deterministic outgoing vector. The
`restitution = 1` on the paddle is now load-bearing for nothing, but it's
harmless to leave.

The lesson, again: physics defaults are great for a starting point; gameplay
"feel" almost always requires a deliberate cheat on top.

### Aha moment: the scoreboard pattern

The cleanest part of this design is that `GameState` doesn't import
SpriteKit. The scene mutates the model; the model exposes a closure the
scene fills in for resets. This means the entire model is unit-testable in
~40 lines of Swift Testing — no simulator, no scene, no nodes, no physics.
That's the right boundary, and it falls out naturally as soon as you stop
trying to make `GameState` know what a paddle is.

## Engineer's Wisdom

- **Make boundaries do work for you.** The `GameState` ↔ `GameScene`
  boundary isn't there for fashion — it's there because if you cross it,
  the scoreboard suddenly knows about physics bodies, and now your tests
  need a render loop. Boundaries that simplify testing are real boundaries.
- **Favor "one calculation per frame" over "one new physics category."**
  Both work. The first one cannot be silently misconfigured.
- **When the build and the language server disagree, trust the build.**
  IDE diagnostics are best-effort. `xcodebuild` is ground truth.
- **Don't reach for `SKAction` when direct property assignment will do.**
  Setting `paddle.position.x` per touch event tracks the finger
  immediately. Animating it would just add input lag.
- **Debounce contact events even when you "know" they fire once.** Physics
  engines are full of "stuck on the seam" edge cases. A 50ms guard around
  paddle hits is cheap insurance.
- **Use `@Observable` defaults.** Letting Swift 6's
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` carry the concurrency story
  means almost no `@MainActor` annotations clutter the code, while still
  getting the safety. Less ceremony, same guarantees.

## If I Were Starting Over...

- I'd probably *still* not have built a Settings screen or a high-score
  store. They'd be the next steps for a real app, but they'd dilute the
  point of this one (which is "minimum viable game in `SpriteView`").
- I'd consider whether the paddle should be a `SKSpriteNode` with a solid
  color texture instead of `SKShapeNode`. `SKShapeNode` is fine but is
  generally a bit slower than a textured sprite — irrelevant here, but a
  reflex worth keeping for bigger games.
- I'd add a tiny "ball trail" effect using `SKEmitterNode`. It's three
  lines of code and turns "minimum viable" into "tactile." Out of scope
  for v1, but the next thing I'd reach for.
- I'd put the paddle width / ball radius / kickoff impulse into a single
  `GameTuning` struct so they're all visible together, instead of as
  scattered `static` constants on `GameScene`. Right now there are only
  five tuning numbers and they all live next to each other, so it's not
  worth the abstraction yet. Watch for the threshold.
