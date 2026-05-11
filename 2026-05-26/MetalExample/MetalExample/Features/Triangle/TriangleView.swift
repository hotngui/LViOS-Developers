import SwiftUI

struct TriangleView: View {
    @State private var viewModel = TriangleViewModel()

    var body: some View {
        VStack {
            TriangleMetalView(viewModel: viewModel)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 16))
                .padding()

            TriangleControls(viewModel: viewModel)
                .padding()

            Spacer()
        }
        .navigationTitle("Triangle")
    }
}

#Preview {
    NavigationStack { TriangleView() }
        .environment(MetalContext())
}
