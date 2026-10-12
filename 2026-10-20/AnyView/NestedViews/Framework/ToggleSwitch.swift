//  Part of the NestedViews target, which is an intentional anti-pattern. This file itself erases nothing.

import SwiftUI

/// The switch of the Toggle card. `@State` has to live in a view, and the ViewModels are rebuilt on every update, so
/// this one piece stays a concrete view. It takes no inputs, so SwiftUI never has a reason to re-run it.
struct ToggleSwitch: View {
    @State private var isEnabled = false

    var body: some View {
        Toggle("Enabled", isOn: $isEnabled)
    }
}
