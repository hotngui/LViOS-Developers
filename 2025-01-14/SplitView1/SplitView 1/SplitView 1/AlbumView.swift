//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 . All rights reserved.
//

import SwiftUI

struct AlbumView: View {
    var body: some View {
        HStack(alignment: .top) {
            Image(.albumCover)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80)
            
            VStack(alignment: .leading) {
                Text("The Beatles")
                    .font(.title)
                Text("Yellow Submarine")
                    .font(.headline)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AlbumView()
}
