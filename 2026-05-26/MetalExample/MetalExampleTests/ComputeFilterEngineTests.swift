import Testing
import UIKit
import Metal
@testable import MetalExample

@MainActor
struct ComputeFilterEngineTests {
    @Test func libraryHasAllExpectedKernels() {
        let metal = MetalContext()
        let names = ["grayscale_kernel", "box_blur_kernel", "sobel_kernel"]
        for name in names {
            #expect(metal.library.makeFunction(name: name) != nil,
                    "Function \(name) not in default library. Available: \(metal.library.functionNames)")
        }
    }

    @Test func sampleImageHasCGImage() {
        let image = SampleImageProvider.makeSampleImage()
        #expect(image.cgImage != nil, "Sample image must be CGImage-backed")
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }

    @Test func grayscaleSucceeds() throws {
        let metal = MetalContext()
        let engine = ComputeFilterEngine(metal: metal)
        let input = SampleImageProvider.makeSampleImage()
        _ = try engine.applyThrowing(filter: .grayscale, to: input)
    }

    @Test func boxBlurSucceeds() throws {
        let metal = MetalContext()
        let engine = ComputeFilterEngine(metal: metal)
        let input = SampleImageProvider.makeSampleImage()
        _ = try engine.applyThrowing(filter: .boxBlur, to: input, blurRadius: 3)
    }

    @Test func sobelSucceeds() throws {
        let metal = MetalContext()
        let engine = ComputeFilterEngine(metal: metal)
        let input = SampleImageProvider.makeSampleImage()
        _ = try engine.applyThrowing(filter: .sobel, to: input)
    }
}
