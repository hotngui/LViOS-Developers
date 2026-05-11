import Testing
@testable import MetalExample

@MainActor
struct TriangleViewModelTests {
    @Test func defaultsAreCorrect() {
        let vm = TriangleViewModel()
        #expect(vm.rotationDegrees == 0)
        #expect(vm.rotationRadians == 0)
        #expect(vm.vertexColors.count == 3)
    }

    @Test func rotationConvertsToRadians() {
        let vm = TriangleViewModel()
        vm.rotationDegrees = 180
        #expect(abs(vm.rotationRadians - .pi) < 0.0001)
    }

    @Test func rotationAtZeroDegrees() {
        let vm = TriangleViewModel()
        vm.rotationDegrees = 360
        #expect(abs(vm.rotationRadians - 2 * .pi) < 0.0001)
    }
}
