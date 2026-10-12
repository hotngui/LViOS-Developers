import SwiftUI
import Testing
@testable import DemoKit

@Suite struct SettingsTests {
    @Test func theEnvironmentDefaultsToTheStandardContainer() {
        #expect(EnvironmentValues().containerStyle == ContainerStyle.standard)
    }

    @Test func theDeviceModelIdentifierIsNeverEmpty() {
        #expect(!DeviceModel.identifier.isEmpty)
    }

    @Test func flagsParseRegardlessOfCase() {
        let arguments = ["app", "-intensity", "HEAVY", "-tickRate", "Fast", "-container", "LazyStack"]
        #expect(LaunchArguments.intensity(from: arguments) == .heavy)
        #expect(LaunchArguments.tickRate(from: arguments) == .fast)
        #expect(LaunchArguments.containerStyle(from: arguments) == .lazyStack)
    }

    @Test func missingOrUnknownValuesFallBackToTheDefaults() {
        #expect(LaunchArguments.intensity(from: ["app"]) == .realistic)
        #expect(LaunchArguments.intensity(from: ["app", "-intensity", "ludicrous"]) == .realistic)
        #expect(LaunchArguments.tickRate(from: ["app", "-tickRate", "turbo"]) == .normal)
        #expect(LaunchArguments.containerStyle(from: ["app", "-container", "grid"]) == .stack)
    }

    /// Review Focus 4: a flag as the last argument has no value.
    @Test func aFlagWithNoValueFallsBack() {
        #expect(LaunchArguments.intensity(from: ["app", "-intensity"]) == .realistic)
        #expect(LaunchArguments.tickRate(from: ["app", "-tickRate"]) == .normal)
        #expect(LaunchArguments.liveUpdatesEnabled(from: ["app", "-liveUpdates"]))
    }

    @Test func liveUpdatesOffTurnsLiveOffAndAnythingElseLeavesItOn() {
        #expect(!LaunchArguments.liveUpdatesEnabled(from: ["app", "-liveUpdates", "OFF"]))
        #expect(LaunchArguments.liveUpdatesEnabled(from: ["app", "-liveUpdates", "on"]))
        #expect(LaunchArguments.liveUpdatesEnabled(from: ["app"]))
    }

    @Test func levelsStrictlyIncreaseAndRatesStrictlyShorten() {
        let counts = Intensity.allCases.map(\.cardCount)
        #expect(counts == counts.sorted())
        #expect(Set(counts).count == counts.count)
        #expect(Intensity.standard == .realistic)
        #expect(Intensity.realistic.cardCount == 200)
        let intervals = TickRate.allCases.map(\.interval)
        #expect(intervals == intervals.sorted(by: >))
        #expect(Set(intervals).count == intervals.count)
        #expect(TickRate.standard == .normal)
        #expect(TickRate.normal.interval == .milliseconds(200))
        #expect(ContainerStyle.standard == .stack)
    }

    @Test @MainActor func demoSettingsReadsAllFourValuesFromItsArguments() {
        let arguments = ["app", "-intensity", "severe", "-tickRate", "slow", "-container", "list", "-liveUpdates", "off"]
        let settings = DemoSettings(arguments: arguments)
        #expect(settings.intensity == .severe)
        #expect(settings.tickRate == .slow)
        #expect(settings.containerStyle == .list)
        #expect(!settings.liveUpdatesEnabled)
        let defaults = DemoSettings(arguments: ["app"])
        #expect(defaults.intensity == .realistic)
        #expect(defaults.tickRate == .normal)
        #expect(defaults.containerStyle == .stack)
        #expect(defaults.liveUpdatesEnabled)
    }

    @Test func theCardCountsAreTheSixInOrderAndTenIsStandard() {
        #expect(CardCount.allCases.map(\.rawValue) == [10, 100, 200, 300, 400, 500])
        #expect(CardCount.standard == .ten)
    }

    @Test func theCardsArgumentParses() {
        #expect(LaunchArguments.cardCount(from: ["app", "-cards", "300"]) == .threeHundred)
        #expect(LaunchArguments.cardCount(from: ["app", "-cards", "10"]) == .ten)
        #expect(LaunchArguments.cardCount(from: ["app", "-intensity", "heavy", "-cards", "500"]) == .fiveHundred)
    }

    @Test func aMissingOrUnknownCardsValueFallsBackToTen() {
        #expect(LaunchArguments.cardCount(from: ["app"]) == .ten)
        #expect(LaunchArguments.cardCount(from: ["app", "-cards"]) == .ten)
        #expect(LaunchArguments.cardCount(from: ["app", "-cards", "many"]) == .ten)
        #expect(LaunchArguments.cardCount(from: ["app", "-cards", "250"]) == .ten)
    }

    /// Review Focus 1.
    @Test func zeroNegativeAndDecimalCardsValuesFallBackToTen() {
        #expect(LaunchArguments.cardCount(from: ["app", "-cards", "0"]) == .ten)
        #expect(LaunchArguments.cardCount(from: ["app", "-cards", "-100"]) == .ten)
        #expect(LaunchArguments.cardCount(from: ["app", "-cards", "300.0"]) == .ten)
    }

    @Test func theEagerVariantNamesItself() {
        #expect(String(localized: AppVariant.eager.name) == "Eager")
        #expect(String(localized: AppVariant.eager.title) == "Eager VStack")
    }

    @Test func theNestedVariantNamesAndExplainsItself() {
        #expect(String(localized: AppVariant.nested.name) == "Nested")
        #expect(String(localized: AppVariant.nested.title) == "Nested + stable id")
        let explanation = "Every card is built from AnyViews inside AnyViews, with stable ids, "
            + "so each card's chrome re-runs on every update, changed or not."
        #expect(String(localized: AppVariant.nested.explanation) == explanation)
    }

    @Test func massiveAndAbsurdComeLastWithTheirCounts() {
        #expect(Array(Intensity.allCases.suffix(2)) == [.massive, .absurd])
        #expect(Intensity.massive.cardCount == 2_000)
        #expect(Intensity.absurd.cardCount == 5_000)
        #expect(String(localized: Intensity.massive.title) == "Massive")
        #expect(String(localized: Intensity.absurd.title) == "Absurd")
    }

    /// Review Focus 1: any case parses, and a misspelling falls back.
    @Test func theTwoLargeLevelsParseInAnyCase() {
        #expect(LaunchArguments.intensity(from: ["app", "-intensity", "massive"]) == .massive)
        #expect(LaunchArguments.intensity(from: ["app", "-intensity", "ABSURD"]) == .absurd)
        #expect(LaunchArguments.intensity(from: ["app", "-intensity", "gigantic"]) == .realistic)
    }

    @Test func theWrappedVariantNamesAndExplainsItself() {
        #expect(String(localized: AppVariant.wrapped.name) == "Wrapped")
        #expect(String(localized: AppVariant.wrapped.title) == "Wrapped + stable id")
        let explanation = "Concrete with one change: each row is wrapped in an AnyView, "
            + "so a List can't template its rows and evaluates every row on every update."
        #expect(String(localized: AppVariant.wrapped.explanation) == explanation)
    }
}
