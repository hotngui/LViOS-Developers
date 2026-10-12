import Testing
@testable import DashboardKit

@Suite struct IntensityTests {
    @Test func intensityValueParsesRegardlessOfCase() {
        #expect(LaunchArguments.intensity(from: ["App", "-intensity", "HEAVY"]) == .heavy)
        #expect(LaunchArguments.intensity(from: ["App", "-intensity", "extreme"]) == .extreme)
    }

    @Test(arguments: [["App"], ["App", "-intensity"], ["App", "-intensity", "bogus"]])
    func missingDanglingOrUnknownValuesFallBackToRealistic(arguments: [String]) {
        #expect(LaunchArguments.intensity(from: arguments) == .realistic)
    }

    @Test func eachLevelIsStrictlyLargerThanThePrevious() {
        let levels = Intensity.allCases
        #expect(zip(levels, levels.dropFirst()).allSatisfy { $0.transactionCount < $1.transactionCount })
        #expect(zip(levels, levels.dropFirst()).allSatisfy { $0.recentRowLimit < $1.recentRowLimit })
        #expect(Intensity.standard == .realistic)
        #expect(Intensity.realistic.transactionCount == 3_000)
    }

    @Test func badgeFlagIsReadFromLaunchArguments() {
        #expect(LaunchArguments.showsEvaluationBadges(from: ["App", "-showEvaluationBadges"]))
        #expect(!LaunchArguments.showsEvaluationBadges(from: ["App"]))
    }

    @Test func liveUpdatesFollowTheLaunchArgument() {
        #expect(!LaunchArguments.liveUpdatesEnabled(from: ["App", "-liveUpdates", "off"]))
        #expect(!LaunchArguments.liveUpdatesEnabled(from: ["App", "-liveUpdates", "OFF"]))
        #expect(LaunchArguments.liveUpdatesEnabled(from: ["App", "-liveUpdates", "on"]))
        #expect(LaunchArguments.liveUpdatesEnabled(from: ["App"]))
    }
}
