import Metal
import Observation

/// Shared Metal device, command queue, and shader library.
///
/// One instance is created at app launch and injected into the SwiftUI
/// environment, so every Metal-backed view in the app shares the same
/// `MTLDevice` and `MTLCommandQueue`.
@Observable
@MainActor
final class MetalContext {
    let device: any MTLDevice
    let commandQueue: any MTLCommandQueue
    let library: any MTLLibrary

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is required to run this app and is not available on this device.")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create a Metal command queue.")
        }
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Failed to load the default Metal library. Make sure the .metal files are part of the build.")
        }
        self.device = device
        self.commandQueue = commandQueue
        self.library = library
    }
}
