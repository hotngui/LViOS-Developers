import SwiftUI

struct ImageFilterView: View {
    @Environment(MetalContext.self) private var metal

    var body: some View {
        ImageFilterContent(metal: metal)
    }
}

private struct ImageFilterContent: View {
    @State private var viewModel: ImageFilterViewModel

    init(metal: MetalContext) {
        _viewModel = State(initialValue: ImageFilterViewModel(metal: metal))
    }

    var body: some View {
        VStack {
            FilterPreview(viewModel: viewModel)
            FilterPicker(viewModel: viewModel)
            BlurRadiusRow(viewModel: viewModel)
            Spacer()
        }
        .padding()
        .navigationTitle("Image Filter")
    }
}

private struct FilterPreview: View {
    let viewModel: ImageFilterViewModel

    var body: some View {
        Group {
            if let image = viewModel.outputImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 16))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }
}

private struct FilterPicker: View {
    @Bindable var viewModel: ImageFilterViewModel

    var body: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(FilterKind.allCases) { kind in
                Text(kind.title).tag(kind)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct BlurRadiusRow: View {
    @Bindable var viewModel: ImageFilterViewModel

    var body: some View {
        if viewModel.selectedFilter == .boxBlur {
            HStack {
                Text("Radius")
                Slider(value: $viewModel.blurRadius, in: 1...10, step: 1)
                Text(viewModel.blurRadius, format: .number.precision(.fractionLength(0)))
                    .monospacedDigit()
            }
        }
    }
}
