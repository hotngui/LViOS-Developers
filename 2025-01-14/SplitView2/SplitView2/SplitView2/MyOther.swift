//
// Created by Joey Jarosz on 1/12/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Kingfisher
import SwiftUI

struct MyOther: View {
    var maxCount: Int = 10

    var body: some View {
        List {
            ForEach((1...maxCount), id: \.self) { indx in
                VStack(alignment: .leading) {
                    MyImageView(indx: indx)
                    Text("Photo \(indx)")
                }
            }
        }
        .listStyle(.plain)
        .padding(.top)
    }
}

#Preview {
    MyOther()
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
                  .url(URL(string: "https://picsum.photos/id/\(indx)/2000/1500")!)
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
