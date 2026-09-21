//
// Created by Joey Jarosz on 10/10/23.
//

import SwiftUI

struct PhotoView: View {
    let urlStr: String
    let indx: Int
    let cachePolicy: URLRequest.CachePolicy

    private let ratio: CGFloat = 0.75

    var body: some View {
        VStack(spacing: 0) {
            Color(.systemGray4)
                .aspectRatio(1 / ratio, contentMode: .fit)
                .overlay {
                    if let url = URL(string: urlStr) {
                        AsyncImage(request: URLRequest(url: url, cachePolicy: cachePolicy),
                                   transaction: Transaction(animation: .easeInOut(duration: 0.15))) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                // Covers both `.empty` and `.failure` — the latter is expected
                                // in "Cache Only" mode when an image was never cached.
                                Image(.placeholder)
                            }
                        }
                    } else {
                        Image(.placeholder)
                    }
                }
                .clipped()

            Text("\(indx+1): \(urlStr)")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 2, leading: 20, bottom: 0, trailing: 20))
        }
    }

    init(_ urlStr: String, indx: Int, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.urlStr = urlStr
        self.indx = indx
        self.cachePolicy = cachePolicy
    }
}

#Preview {
    Group {
        PhotoView("https://photos.zillowstatic.com/fp/da76aa88c3e4bafcc222bae3f14f73cd-p_f.jpg", indx: 0)
        PhotoView("https://photos.zillowstatic.com/fp/56f860b08c6eb60f0d63bb9ed75700b7-p_f.jpg", indx: 0)
    }
}
