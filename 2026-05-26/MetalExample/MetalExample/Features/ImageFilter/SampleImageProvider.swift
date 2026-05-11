import SwiftUI
import UIKit

/// Generates a sample input image at app launch using `ImageRenderer`. We
/// avoid bundling photo assets so the demo is self-contained.
@MainActor
enum SampleImageProvider {
    static let outputSize = CGSize(width: 512, height: 512)

    static func makeSampleImage() -> UIImage {
        let renderer = ImageRenderer(content: SampleImageContent())
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(outputSize)
        return renderer.uiImage ?? UIImage()
    }
}

private struct SampleImageContent: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple, .blue, .cyan, .mint],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: CGFloat(80 + i * 60))
            }

            VStack {
                Image(systemName: "swift")
                    .font(.system(size: 120))
                    .foregroundStyle(.white)
                Text("Metal")
                    .font(.system(size: 72))
                    .bold()
                    .foregroundStyle(.white)
            }
        }
        .frame(width: SampleImageProvider.outputSize.width,
               height: SampleImageProvider.outputSize.height)
    }
}
