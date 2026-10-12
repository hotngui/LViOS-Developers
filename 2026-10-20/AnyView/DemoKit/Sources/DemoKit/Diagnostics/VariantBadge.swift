import SwiftUI

/// The colored badge naming the variant. Text on color, never color alone.
struct VariantBadge: View {
    let variant: AppVariant

    var body: some View {
        Text(variant.title)
            .bold()
            .foregroundStyle(.black)
            .padding(.horizontal)
            .background(variant.tint, in: .capsule)
    }
}
