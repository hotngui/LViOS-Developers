import Foundation
import Testing
@testable import DemoKit

@MainActor
@Suite struct CompactFrameMeterViewTests {
    @Test func theCardCountLabelUsesTheSingularForExactlyOne() {
        #expect(String(localized: CompactFrameMeterView.cardCountLabel(1)) == "1 card")
        #expect(String(localized: CompactFrameMeterView.cardCountLabel(0)) == "0 cards")
        #expect(String(localized: CompactFrameMeterView.cardCountLabel(2)) == "2 cards")
        #expect(String(localized: CompactFrameMeterView.cardCountLabel(300)) == "300 cards")
    }
}
