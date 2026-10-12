import SwiftUI

/// A big number. With stable identity the digits roll on change; a re-created card snaps.
public struct StatCard: View {
    private let id: Int
    private let title: String
    private let value: Double

    public init(id: Int, title: String, value: Double) {
        self.id = id
        self.title = title
        self.value = value
    }

    public var body: some View {
        CardChrome(id: id, title: title) {
            Text(Int(value), format: .number)
                .font(.largeTitle)
                .bold()
                .contentTransition(.numericText(value: value))
                .animation(.default, value: value)
        }
    }
}
