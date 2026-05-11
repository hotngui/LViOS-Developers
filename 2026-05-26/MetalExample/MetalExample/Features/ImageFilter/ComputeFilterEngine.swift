import CoreGraphics
import Metal
import UIKit

/// Runs Metal compute kernels against a `UIImage` input and returns a new
/// `UIImage`. All work is dispatched on the main actor because the textures
/// are small (512x512) and the demo blocks until the command buffer finishes.
@MainActor
final class ComputeFilterEngine {
    private let metal: MetalContext
    private let pipelines: [FilterKind: any MTLComputePipelineState]

    init(metal: MetalContext) {
        self.metal = metal

        var built: [FilterKind: any MTLComputePipelineState] = [:]
        for kind in FilterKind.allCases {
            guard let name = kind.kernelName,
                  let function = metal.library.makeFunction(name: name) else {
                continue
            }
            do {
                built[kind] = try metal.device.makeComputePipelineState(function: function)
            } catch {
                fatalError("Failed to build \(name) pipeline: \(error)")
            }
        }
        self.pipelines = built
    }

    enum FilterError: Error, CustomStringConvertible {
        case missingPipeline
        case missingCGImage
        case inputTextureCreationFailed
        case outputTextureCreationFailed
        case commandBufferCreationFailed
        case encoderCreationFailed
        case commandBufferFailed(any Error)
        case imageReconstructionFailed

        var description: String {
            switch self {
            case .missingPipeline:                return "Pipeline not found for filter"
            case .missingCGImage:                 return "Input UIImage has no CGImage"
            case .inputTextureCreationFailed:     return "Could not draw CGImage into input texture"
            case .outputTextureCreationFailed:    return "makeTexture(descriptor:) returned nil"
            case .commandBufferCreationFailed:    return "makeCommandBuffer() returned nil"
            case .encoderCreationFailed:          return "makeComputeCommandEncoder() returned nil"
            case .commandBufferFailed(let err):   return "Command buffer failed: \(err)"
            case .imageReconstructionFailed:      return "Reconstructing UIImage from output texture failed"
            }
        }
    }

    func apply(filter: FilterKind, to image: UIImage, blurRadius: Int = 3) -> UIImage? {
        try? applyThrowing(filter: filter, to: image, blurRadius: blurRadius)
    }

    func applyThrowing(filter: FilterKind, to image: UIImage, blurRadius: Int = 3) throws -> UIImage {
        if filter == .original { return image }
        guard let pipeline = pipelines[filter] else { throw FilterError.missingPipeline }
        guard let cgImage = image.cgImage else { throw FilterError.missingCGImage }

        guard let inputTexture = makeInputTexture(from: cgImage) else {
            throw FilterError.inputTextureCreationFailed
        }

        let outDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: inputTexture.width,
            height: inputTexture.height,
            mipmapped: false
        )
        outDescriptor.usage = [.shaderRead, .shaderWrite]
        outDescriptor.storageMode = .shared

        guard let outputTexture = metal.device.makeTexture(descriptor: outDescriptor) else {
            throw FilterError.outputTextureCreationFailed
        }
        guard let commandBuffer = metal.commandQueue.makeCommandBuffer() else {
            throw FilterError.commandBufferCreationFailed
        }
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw FilterError.encoderCreationFailed
        }

        encoder.label = filter.rawValue
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)

        if filter == .boxBlur {
            var radius = Int32(blurRadius)
            encoder.setBytes(&radius, length: MemoryLayout<Int32>.stride, index: 0)
        }

        let groupSize = MTLSize(width: 16, height: 16, depth: 1)
        let groupCount = MTLSize(
            width:  (inputTexture.width  + groupSize.width  - 1) / groupSize.width,
            height: (inputTexture.height + groupSize.height - 1) / groupSize.height,
            depth: 1
        )
        encoder.dispatchThreadgroups(groupCount, threadsPerThreadgroup: groupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let err = commandBuffer.error {
            throw FilterError.commandBufferFailed(err)
        }

        guard let result = Self.makeUIImage(from: outputTexture) else {
            throw FilterError.imageReconstructionFailed
        }
        return result
    }

    /// Draws the CGImage into a fresh RGBA8 / premultiplied-last bitmap,
    /// then uploads those bytes into a Metal texture. We do this instead of
    /// using `MTKTextureLoader`, which fails to decode CGImages that come
    /// from `ImageRenderer` on some iOS Simulator versions.
    private func makeInputTexture(from cgImage: CGImage) -> (any MTLTexture)? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)

        let drew: Bool = bytes.withUnsafeMutableBytes { buffer in
            guard let base = buffer.baseAddress,
                  let context = CGContext(
                      data: base,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drew else { return nil }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = .shaderRead
        descriptor.storageMode = .shared

        guard let texture = metal.device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        let region = MTLRegionMake2D(0, 0, width, height)
        bytes.withUnsafeBytes { buffer in
            if let base = buffer.baseAddress {
                texture.replace(region: region, mipmapLevel: 0, withBytes: base, bytesPerRow: bytesPerRow)
            }
        }
        return texture
    }

    private static func makeUIImage(from texture: any MTLTexture) -> UIImage? {
        let bytesPerRow = texture.width * 4
        let byteCount = bytesPerRow * texture.height
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        bytes.withUnsafeMutableBytes { buf in
            if let base = buf.baseAddress {
                texture.getBytes(base, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
            }
        }

        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        guard let cgImage = CGImage(
            width: texture.width,
            height: texture.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
