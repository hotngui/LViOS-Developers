import simd

/// Mirror of the `Uniforms` struct in `Triangle.metal`.
///
/// Field order and alignment must match exactly. `SIMD4<Float>` has 16-byte
/// alignment, so Swift inserts 12 bytes of padding after `angle`, matching the
/// layout Metal uses on the shader side.
struct TriangleUniforms {
    var angle: Float = 0
    var color0: SIMD4<Float> = SIMD4(1, 0, 0, 1)
    var color1: SIMD4<Float> = SIMD4(0, 1, 0, 1)
    var color2: SIMD4<Float> = SIMD4(0, 0, 1, 1)
}
