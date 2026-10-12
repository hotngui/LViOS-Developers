import Testing
@testable import DemoKit

@Suite struct CardKindTests {
    @Test func thereAreFiveKindsInOrder() {
        #expect(CardKind.allCases == [.stat, .gauge, .toggle, .sparkline, .pulse])
    }
}
