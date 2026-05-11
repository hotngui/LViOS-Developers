import SwiftUI
import simd

extension Color {
    /// Resolves a SwiftUI `Color` to a linear-sRGB SIMD vector that can be
    /// uploaded directly to a Metal uniform buffer.
    func toSIMD4(in environment: EnvironmentValues) -> SIMD4<Float> {
        let resolved = self.resolve(in: environment)
        return SIMD4(resolved.red, resolved.green, resolved.blue, resolved.opacity)
    }
}
