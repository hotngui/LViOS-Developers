import Observation
import UIKit

@Observable
@MainActor
final class ImageFilterViewModel {
    let sourceImage: UIImage
    var selectedFilter: FilterKind = .original {
        didSet { reapplyFilter() }
    }
    var blurRadius: Double = 3 {
        didSet { if selectedFilter == .boxBlur { reapplyFilter() } }
    }
    private(set) var outputImage: UIImage?

    private let engine: ComputeFilterEngine

    init(metal: MetalContext) {
        self.sourceImage = SampleImageProvider.makeSampleImage()
        self.engine = ComputeFilterEngine(metal: metal)
        self.outputImage = sourceImage
    }

    func reapplyFilter() {
        outputImage = engine.apply(
            filter: selectedFilter,
            to: sourceImage,
            blurRadius: Int(blurRadius)
        )
    }
}
