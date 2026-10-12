import SwiftUI
import Testing
@testable import DashboardKit

@Suite @MainActor struct DiagnosticsDefaultsTests {
    @Test func badgesAreOffByDefault() {
        #expect(EnvironmentValues().showsEvaluationBadges == false)
    }

    @Test func deviceModelIdentifierIsNotEmpty() {
        #expect(!DeviceModel.identifier.isEmpty)
    }
}
