import SwiftUI
import Testing
@testable import DemoKit

@MainActor
@Suite struct CardChromeTests {
    @Test func theChromeRecordsOneBodyRunEachTimeItsBodyRuns() {
        let chrome = CardChrome(id: 1, title: "Orders 1") {
            Text("42")
        }
        let before = BodyCounter.shared.count
        _ = chrome.body
        _ = chrome.body
        #expect(BodyCounter.shared.count == before + 2)
    }
}
