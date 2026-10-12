// swift-tools-version: 6.2
import PackageDescription

// Approachable Concurrency, matching the app targets' "Approachable Concurrency = Yes" build setting.
let approachableConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances")
]

let package = Package(
    name: "DemoKit",
    // macOS is listed only so `swift test` can run the unit tests on the Mac without a simulator.
    platforms: [.iOS("27.0"), .macOS("27.0")],
    products: [
        .library(name: "DemoKit", targets: ["DemoKit"])
    ],
    targets: [
        .target(name: "DemoKit", swiftSettings: approachableConcurrency),
        .testTarget(name: "DemoKitTests", dependencies: ["DemoKit"], swiftSettings: approachableConcurrency)
    ]
)
