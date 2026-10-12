import Foundation
import Observation

/// The demo's user-adjustable settings, shared by the settings menu, the HUD, the container, and the tick loop.
@MainActor
@Observable
public final class DemoSettings {
    public var intensity: Intensity
    public var tickRate: TickRate
    public var containerStyle: ContainerStyle
    public var liveUpdatesEnabled: Bool

    public init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        intensity = LaunchArguments.intensity(from: arguments)
        tickRate = LaunchArguments.tickRate(from: arguments)
        containerStyle = LaunchArguments.containerStyle(from: arguments)
        liveUpdatesEnabled = LaunchArguments.liveUpdatesEnabled(from: arguments)
    }
}
