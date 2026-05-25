//
// Created by Joey Jarosz on 5/7/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SpriteKit

/// The single SKScene that owns paddle, ball, and walls. Contact and per-frame logic
/// pushes score and game-over events into the shared `GameState`.
final class GameScene: SKScene, SKPhysicsContactDelegate {
    private let gameState: GameState

    private let paddle = SKShapeNode()
    private let ball = SKShapeNode(circleOfRadius: GameScene.ballRadius)

    private var lastPaddleHitTime: TimeInterval = 0

    private static let ballRadius: CGFloat = 8
    private static let paddleHeight: CGFloat = 12
    private static let paddleYOffset: CGFloat = 60
    private static let paddleHitDebounce: TimeInterval = 0.05
    private static let maxBallSpeed: CGFloat = 600
    private static let minBallSpeed: CGFloat = 220
    /// Maximum deflection from vertical for an edge-of-paddle hit. 60° gives a sharp
    /// but still recoverable angle at the extremes.
    private static let maxBounceAngle: CGFloat = .pi / 3

    init(size: CGSize, gameState: GameState) {
        self.gameState = gameState
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0, y: 0)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black

        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        configureWalls()
        configurePaddle()
        configureBall()
        kickoff()
    }

    // MARK: - Setup

    private func configureWalls() {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: size.width, y: 0))

        let body = SKPhysicsBody(edgeChainFrom: path)
        body.categoryBitMask = PhysicsCategory.wall.rawValue
        body.friction = 0
        body.restitution = 1.0
        physicsBody = body
    }

    private func configurePaddle() {
        let paddleWidth = size.width * 0.22
        let paddleSize = CGSize(width: paddleWidth, height: Self.paddleHeight)
        let rect = CGRect(origin: CGPoint(x: -paddleWidth / 2, y: -Self.paddleHeight / 2),
                          size: paddleSize)

        paddle.path = CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        paddle.fillColor = .white
        paddle.strokeColor = .clear
        paddle.position = CGPoint(x: size.width / 2, y: Self.paddleYOffset)

        let body = SKPhysicsBody(rectangleOf: paddleSize)
        body.isDynamic = false
        body.friction = 0
        body.restitution = 1.0
        body.categoryBitMask = PhysicsCategory.paddle.rawValue
        body.contactTestBitMask = PhysicsCategory.ball.rawValue
        body.collisionBitMask = PhysicsCategory.ball.rawValue
        paddle.physicsBody = body

        addChild(paddle)
    }

    private func configureBall() {
        ball.fillColor = .white
        ball.strokeColor = .clear
        ball.position = CGPoint(x: size.width / 2, y: size.height / 2)

        let body = SKPhysicsBody(circleOfRadius: Self.ballRadius)
        body.isDynamic = true
        body.allowsRotation = false
        body.friction = 0
        body.restitution = 1.0
        body.linearDamping = 0
        body.angularDamping = 0
        body.categoryBitMask = PhysicsCategory.ball.rawValue
        body.contactTestBitMask = PhysicsCategory.paddle.rawValue
        body.collisionBitMask = PhysicsCategory.wall.rawValue | PhysicsCategory.paddle.rawValue
        ball.physicsBody = body

        addChild(ball)
    }

    /// Apply the launch impulse to the ball — small horizontal variance plus a downward push.
    private func kickoff() {
        let dx = CGFloat.random(in: -60...60)
        let dy: CGFloat = -180
        ball.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
    }

    // MARK: - Reset

    /// Recenter the paddle and ball, reapply the kickoff impulse. Called by `GameState.restart()`.
    func reset() {
        lastPaddleHitTime = 0

        paddle.position.x = size.width / 2

        ball.position = CGPoint(x: size.width / 2, y: size.height / 2)
        ball.physicsBody?.velocity = .zero
        ball.physicsBody?.angularVelocity = 0
        ball.physicsBody?.isDynamic = true

        kickoff()
    }

    // MARK: - Per-frame

    override func update(_ currentTime: TimeInterval) {
        clampBallSpeed()

        if !gameState.isGameOver && ball.position.y < -Self.ballRadius {
            ball.physicsBody?.isDynamic = false
            gameState.endGame()
        }
    }

    private func clampBallSpeed() {
        guard let velocity = ball.physicsBody?.velocity else { return }
        let speed = (velocity.dx * velocity.dx + velocity.dy * velocity.dy).squareRoot()
        guard speed > Self.maxBallSpeed else { return }
        let scale = Self.maxBallSpeed / speed
        ball.physicsBody?.velocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(to: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        movePaddle(to: touches)
    }

    private func movePaddle(to touches: Set<UITouch>) {
        guard let location = touches.first?.location(in: self) else { return }
        let half = paddle.frame.width / 2
        paddle.position.x = min(max(location.x, half), size.width - half)
    }

    // MARK: - Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let paddleHitMask = PhysicsCategory.ball.rawValue | PhysicsCategory.paddle.rawValue
        guard mask == paddleHitMask else { return }

        let now = CACurrentMediaTime()
        guard now - lastPaddleHitTime > Self.paddleHitDebounce else { return }
        lastPaddleHitTime = now

        applyPaddleBounceAngle()
        gameState.registerPaddleHit()
    }

    /// Override SpriteKit's flat-surface reflection: deflect the ball based on where
    /// it struck the paddle, so edge hits produce sharp angles and centered hits go
    /// nearly straight up. Preserves current speed (with a floor) so the rally stays
    /// lively.
    private func applyPaddleBounceAngle() {
        guard let body = ball.physicsBody else { return }

        let halfWidth = paddle.frame.width / 2
        let rawOffset = (ball.position.x - paddle.position.x) / halfWidth
        let offset = max(-1, min(1, rawOffset))
        let angle = offset * GameScene.maxBounceAngle

        let v = body.velocity
        let currentSpeed = (v.dx * v.dx + v.dy * v.dy).squareRoot()
        let speed = max(currentSpeed, GameScene.minBallSpeed)

        body.velocity = CGVector(dx: speed * sin(angle), dy: speed * cos(angle))
    }
}
