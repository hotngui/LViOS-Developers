import SwiftUI

extension Binding where Value: Sendable {
    /// A binding that starts timing `interaction` whenever a control sets a new value through it.
    @MainActor
    public func timed(_ interaction: Interaction, timer: InteractionTimer = .shared) -> Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { newValue, transaction in
                timer.begin(interaction)
                self.transaction(transaction).wrappedValue = newValue
            }
        )
    }
}
