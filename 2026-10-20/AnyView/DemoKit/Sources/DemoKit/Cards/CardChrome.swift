import SwiftUI

/// The chrome every card shares: title, Remove button, background, the appearance count, and the body count.
///
/// The store is read from the environment only inside the Remove action, so this view establishes no dependency on
/// any store property and the cards need no closures as inputs.
public struct CardChrome<Content: View>: View {
    private let id: Int
    private let title: String
    private let content: Content
    @Environment(DashboardStore.self) private var store

    public init(id: Int, title: String, @ViewBuilder content: () -> Content) {
        self.id = id
        self.title = title
        self.content = content()
    }

    public var body: some View {
        // Counted here, not in `onAppear`: a card that SwiftUI re-runs without re-creating appears only once.
        BodyCounter.shared.record()
        return VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Remove \(title)", systemImage: "xmark.circle") {
                    withAnimation {
                        store.remove(id: id)
                    }
                }
                .labelStyle(.iconOnly)
                .minimumTapTarget()
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .onAppear {
            AppearanceCounter.shared.record()
        }
    }
}
