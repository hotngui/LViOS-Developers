import Testing
@testable import MetalExample

struct ShaderDemoTests {
    @Test func allDemosHaveUniqueIds() {
        let ids = Set(ShaderDemo.all.map(\.id))
        #expect(ids.count == ShaderDemo.all.count)
    }

    @Test func functionNamesMatchKindRawValues() {
        for demo in ShaderDemo.all {
            #expect(demo.kind.functionName == demo.kind.rawValue)
        }
    }

    @Test func gallerySeededWithThreeDemos() {
        #expect(ShaderDemo.all.count == 3)
    }
}
