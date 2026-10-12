import Testing
@testable import DashboardKit

@Suite struct AppVariantTests {
    /// The start screen's explanation is on camera in every capture, so its section count must match the dashboard.
    @Test func computedExplanationStatesTheCurrentSectionCount() {
        let text = String(localized: AppVariant.computed.explanation)
        #expect(text.contains("\(DashboardSection.allCases.count)"))
    }
}
