import SwiftUI
import MetalKit

/// `UIViewRepresentable` wrapping an `MTKView`. SwiftUI owns the view-model
/// and pushes its state into the renderer on every `updateUIView` call.
struct TriangleMetalView: UIViewRepresentable {
    let viewModel: TriangleViewModel

    @Environment(\.self) private var environment
    @Environment(MetalContext.self) private var metal

    func makeCoordinator() -> TriangleRenderer {
        TriangleRenderer(metal: metal)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = metal.device
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1)
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.framebufferOnly = true
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        let resolved = viewModel.vertexColors.map { $0.toSIMD4(in: environment) }
        context.coordinator.update(rotation: viewModel.rotationRadians, colors: resolved)
    }
}
