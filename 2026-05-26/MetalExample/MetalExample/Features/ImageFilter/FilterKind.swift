import Foundation

/// One of the compute-shader image filters supported by `ComputeFilterEngine`.
enum FilterKind: String, CaseIterable, Identifiable, Hashable {
    case original
    case grayscale
    case boxBlur
    case sobel

    var id: Self { self }

    var title: String {
        switch self {
        case .original:  "Original"
        case .grayscale: "Grayscale"
        case .boxBlur:   "Blur"
        case .sobel:     "Edge"
        }
    }

    /// Name of the corresponding `kernel` function in `Filters.metal`.
    /// `original` has no kernel — it returns the input unchanged.
    var kernelName: String? {
        switch self {
        case .original:  nil
        case .grayscale: "grayscale_kernel"
        case .boxBlur:   "box_blur_kernel"
        case .sobel:     "sobel_kernel"
        }
    }
}
