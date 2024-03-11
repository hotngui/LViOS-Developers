//
// Created by Joey Jarosz on 3/9/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Kingfisher
import MusicKit
import SwiftUI

struct AlbumRowView: View {
    enum Constants {
        static let width = 60.0
        static let height = 60.0
    }
    
    var album: Album
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .stroke(lineWidth: 0.3)
                    .frame(width: Constants.width, height: Constants.height)
                KFImage
                    .url(album.artwork?.url(width: Int(Constants.width), height: Int(Constants.height)))
                    .placeholder {
                        Image(systemName: "music.note")
                            .frame(width: Constants.width, height: Constants.height)
                            .foregroundStyle(.gray)
                    }
            }
            
            VStack(alignment: .leading) {
                Text(album.title)
                    .font(.headline)
                
                Text(album.artistName)
                    .font(.caption)
                
                Spacer()
            }
        }
    }
}

//#Preview {
//    AlbumView()
//}
