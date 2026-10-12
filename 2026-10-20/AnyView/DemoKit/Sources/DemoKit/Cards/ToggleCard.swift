import SwiftUI

/// A toggle on card-local state. Flip it: with stable identity it stays; a re-created card resets it within one tick.
public struct ToggleCard: View {
    private let id: Int
    private let title: String
    private let value: Double
    @State private var isEnabled = false

    public init(id: Int, title: String, value: Double) {
        self.id = id
        self.title = title
        self.value = value
    }

    public var body: some View {
        CardChrome(id: id, title: title) {
            Toggle("Enabled", isOn: $isEnabled)
            Text("Pending \(Int(value), format: .number)")
                .foregroundStyle(.secondary)
        }
    }
}
