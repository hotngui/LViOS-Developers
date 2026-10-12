import SwiftUI

extension EnvironmentValues {
    /// Whether the dashboard's live-activity feed ticks. On by default; `-liveUpdates off` or the settings menu turns it off.
    @Entry public var liveUpdatesEnabled = true
}
