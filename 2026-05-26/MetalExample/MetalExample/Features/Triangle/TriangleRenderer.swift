import MetalKit
import simd

/// `MTKViewDelegate` that owns the render pipeline and submits draw calls
/// for the Triangle demo. Created once per `TriangleMetalView` instance.
@MainActor
final class TriangleRenderer: NSObject, MTKViewDelegate {
    private let metal: MetalContext
    private let pipelineState: any MTLRenderPipelineState
    private var uniforms = TriangleUniforms()

    init(metal: MetalContext) {
        self.metal = metal

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = "Triangle pipeline"
        descriptor.vertexFunction = metal.library.makeFunction(name: "triangle_vertex")
        descriptor.fragmentFunction = metal.library.makeFunction(name: "triangle_fragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            self.pipelineState = try metal.device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Failed to build Triangle pipeline state: \(error)")
        }

        super.init()
    }

    func update(rotation: Float, colors: [SIMD4<Float>]) {
        uniforms.angle = rotation
        if colors.count > 0 { uniforms.color0 = colors[0] }
        if colors.count > 1 { uniforms.color1 = colors[1] }
        if colors.count > 2 { uniforms.color2 = colors[2] }
    }

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Nothing to do — clip-space coordinates make this resolution-independent.
    }

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            drawOnMain(in: view)
        }
    }

    private func drawOnMain(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = metal.commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBytes(&uniforms,
                               length: MemoryLayout<TriangleUniforms>.stride,
                               index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
