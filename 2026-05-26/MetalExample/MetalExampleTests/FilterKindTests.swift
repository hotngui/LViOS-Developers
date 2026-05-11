import Testing
@testable import MetalExample

struct FilterKindTests {
    @Test func originalHasNoKernel() {
        #expect(FilterKind.original.kernelName == nil)
    }

    @Test func nonOriginalFiltersHaveKernels() {
        for kind in FilterKind.allCases where kind != .original {
            #expect(kind.kernelName != nil, "\(kind) must have a kernel name")
        }
    }

    @Test func allCasesAreCovered() {
        #expect(FilterKind.allCases.count == 4)
    }

    @Test func titlesAreNonEmpty() {
        for kind in FilterKind.allCases {
            #expect(!kind.title.isEmpty)
        }
    }
}
