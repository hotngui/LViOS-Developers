import SwiftUI

struct TriangleControls: View {
    @Bindable var viewModel: TriangleViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Rotation")
                Slider(value: $viewModel.rotationDegrees, in: 0...360)
                Text(viewModel.rotationDegrees, format: .number.precision(.fractionLength(0)))
                    .monospacedDigit()
            }

            VertexColorRow(viewModel: viewModel)

            Button("Reset", systemImage: "arrow.counterclockwise") {
                viewModel.rotationDegrees = 0
                viewModel.vertexColors = [.red, .green, .blue]
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct VertexColorRow: View {
    @Bindable var viewModel: TriangleViewModel

    var body: some View {
        HStack {
            Text("Vertices")
            Spacer()
            ForEach(viewModel.vertexColors.indices, id: \.self) { index in
                ColorPicker("Vertex \(index)",
                            selection: $viewModel.vertexColors[index],
                            supportsOpacity: false)
                    .labelsHidden()
            }
        }
    }
}
