//
// Created by Joey Jarosz on 12/15/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import Kingfisher

let gridLocalCache =
    ImageCache(memoryStorage: MemoryStorage.Backend<KFCrossPlatformImage>(config: MemoryStorage.Config(totalCostLimit: 1)),
               diskStorage: try! DiskStorage.Backend<Data>(config: DiskStorage.Config(name: "GridCache", sizeLimit: 20_000_000)))

struct GridView: View {
    @State var count: Int = 4
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 10),
        GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 10)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVGrid(columns: columns) {
                    ForEach((0..<count), id: \.self) { _ in
                        LocalImageView(indx: 1)
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        count = 4
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        count += 2
                    } label: {
                        Image(systemName: "plus.diamond.fill")
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Grid Memory")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Custom Image

struct LocalImageView: View {
    @State var mySize: CGSize = .zero
    var indx: Int
    
    public var body: some View {
        Color.clear
          .aspectRatio(3 / 2, contentMode: .fit)
          .overlay {
              KFImage
                  .url(URL(string: "https://picsum.photos/id/\(indx)/5000/3333")!, cacheKey: "Grid-\(indx)")
                  .targetCache(gridLocalCache)
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
                  .fade(duration: 0.25)
                  .resizable()
            }
    }
}

#Preview {
    GridView()
}
