//  Part of the NestedViews target, which is an intentional anti-pattern. This file itself erases nothing.

import SwiftUI

/// The dot of the Pulse card. It holds the animation's `@State`, which has to live in a view, so it stays a concrete
/// view with no inputs. Static under Reduce Motion, like `PulseCard`.
struct PulseDot: View {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(.tint)
            .frame(width: 24, height: 24)
            .scaleEffect(isPulsing ? 1.4 : 1)
            .accessibilityHidden(true)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}
