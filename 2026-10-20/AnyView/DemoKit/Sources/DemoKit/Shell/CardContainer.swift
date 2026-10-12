import SwiftUI

/// The dashboard's container, chosen by the shared setting so every app uses the same one. Its content is the app's
/// `ForEach`. The list-row modifiers are applied to the `ForEach`, so they reach every row of every app alike.
public struct CardContainer<Content: View>: View {
    private let content: Content
    @Environment(\.containerStyle) private var style

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        switch style {
        case .stack:
            ScrollView {
                VStack {
                    content
                }
                .padding()
            }
        case .lazyStack:
            ScrollView {
                LazyVStack {
                    content
                }
                .padding()
            }
        case .list:
            List {
                content
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
        }
    }
}
