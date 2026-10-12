import SwiftUI

/// A continuously pulsing dot. With stable identity it pulses smoothly; a re-created card restarts the animation on
/// every tick, so it looks frozen or jittery. Static under Reduce Motion.
public struct PulseCard: View {
    private let id: Int
    private let title: String
    private let value: Double
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(id: Int, title: String, value: Double) {
        self.id = id
        self.title = title
        self.value = value
    }

    public var body: some View {
        CardChrome(id: id, title: title) {
            HStack {
                Circle()
                    .fill(.tint)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isPulsing ? 1.4 : 1)
                    .accessibilityHidden(true)
                Text("Rate \(Int(value), format: .number)")
                    .foregroundStyle(.secondary)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
}
