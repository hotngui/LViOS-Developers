import Testing
@testable import DashboardKit

@Suite @MainActor struct DemoSettingsTests {
    @Test func settingsReadLaunchArguments() {
        let settings = DemoSettings(arguments: ["App", "-intensity", "severe", "-showEvaluationBadges"])
        #expect(settings.intensity == .severe)
        #expect(settings.showsEvaluationBadges)
    }

    /// Badges only redraw when told to, so a reset must both clear the counts and bump the badge generation.
    @Test func resettingBodyRunCountsClearsTheCounterAndBumpsTheBadgeGeneration() {
        let settings = DemoSettings(arguments: ["App"])
        let counter = EvaluationCounter()
        counter.record(.budget)
        counter.record(.budget)
        settings.resetBodyRunCounts(counter)
        #expect(counter.count(for: .budget) == 0)
        #expect(settings.badgeResetGeneration == 1)
    }

    @Test func badgesDefaultToOff() {
        let settings = DemoSettings(arguments: ["App"])
        #expect(settings.intensity == .realistic)
        #expect(!settings.showsEvaluationBadges)
    }

    @Test func liveUpdatesDefaultToOnAndReadTheLaunchArgument() {
        #expect(DemoSettings(arguments: ["App"]).liveUpdatesEnabled)
        #expect(!DemoSettings(arguments: ["App", "-liveUpdates", "off"]).liveUpdatesEnabled)
    }
}
