import Observation
import SwiftUI

/// State for the Triangle demo: rotation angle and the three vertex tints.
@Observable
@MainActor
final class TriangleViewModel {
    var rotationDegrees: Double = 0
    var vertexColors: [Color] = [.red, .green, .blue]

    var rotationRadians: Float {
        Float(rotationDegrees * .pi / 180)
    }
}
