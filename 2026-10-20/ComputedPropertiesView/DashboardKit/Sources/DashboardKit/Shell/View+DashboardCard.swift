import SwiftUI

extension View {
    /// The card chrome every dashboard section uses. A plain function, not a view type, so it adds no invalidation boundary.
    public func dashboardCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.background.secondary, in: .rect(cornerRadius: 16))
    }
}
