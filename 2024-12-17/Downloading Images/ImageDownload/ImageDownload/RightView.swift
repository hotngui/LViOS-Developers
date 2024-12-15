//
// Created by Joey Jarosz on 11/30/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import Kingfisher


public struct RightView: View {
    var maxCount: Int = 2000
    @State var isOpen: Bool = false
    @State var mySize: CGSize = .zero
    
    public var body: some View {
        NavigationStack {
            List {
                ForEach((1...maxCount), id: \.self) { indx in
                    VStack(alignment: .leading) {
                        MyImageView(indx: indx)
                        Text("Photo \(indx)")
                    }
                }
            }
            .toolbar {
                Button("Clear Cache") {
                    Task { @MainActor in
                        await withCheckedContinuation { continuation in
                            ImageCache.default.clearDiskCache {
                                ImageCache.default.clearMemoryCache()
                                continuation.resume()
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Right Way")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RightView(maxCount: 15)
}

// MARK: - Custom Image

struct MyImageView: View {
    @State var mySize: CGSize = .zero
    var indx: Int
    
    public var body: some View {
        Color.clear
          .aspectRatio(3 / 2, contentMode: .fit)
          .overlay {
              KFImage
                  .url(URL(string: "https://picsum.photos/id/\(indx)/5000/3333")!)
                  .placeholder { progress in
                      Rectangle()
                          .fill(.clear)
                          .border(.secondary, width: 0.5)
                          .opacity(0.4)
                        .aspectRatio(3 / 2, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .imageScale(.large)
                                .foregroundColor(.secondary)
                                .opacity(0.4)
                                .scaleEffect(.init(3.0))
                        }
                  }
//                  .setProcessor(DownsamplingImageProcessor(size: mySize))
//                  .cacheOriginalImage()
                  .fade(duration: 0.25)
                  .resizable()
            }
    }
}
