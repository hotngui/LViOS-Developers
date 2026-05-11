import Foundation

/// One entry in the shader gallery. The `kind` value identifies which
/// `[[stitchable]]` Metal function to bind via `ShaderLibrary`.
struct ShaderDemo: Identifiable, Hashable {
    enum Kind: String, Hashable {
        case plasma
        case ripple
        case valueNoise

        /// Name of the corresponding `[[stitchable]]` function in `Shaders.metal`.
        var functionName: String { rawValue }
    }

    let id: Kind
    let title: String
    let summary: String
    var kind: Kind { id }

    static let all: [ShaderDemo] = [
        ShaderDemo(id: .plasma,
                   title: "Plasma",
                   summary: "Classic trigonometric color field driven by time."),
        ShaderDemo(id: .ripple,
                   title: "Ripple",
                   summary: "Concentric sine waves emanating from the center."),
        ShaderDemo(id: .valueNoise,
                   title: "Value Noise",
                   summary: "Hash-based value noise that drifts over time.")
    ]
}
