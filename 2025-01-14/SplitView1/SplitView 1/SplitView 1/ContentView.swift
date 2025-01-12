//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

// Demonstrates how to use `NavigationSplitView` to create a two column display
// that automatically adjusts its display based on the horizontal "size class" value
//
struct ContentView: View {
    @State var selection: Item?
    
    var body: some View {
        NavigationSplitView {
            VStack {
                AlbumView()
                    .padding()
                
                List(SampleData.items, selection: $selection) { item in
                    NavigationLink(value: item) {
                        Text("\(item.name)")
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Playlist")
        } detail: {
            PlaybackView(item: selection)
        }
    }
}

#Preview("Portrait", traits: .portrait) {
    ContentView()
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
}

#Preview("Landscape", traits: .landscapeLeft) {
    ContentView()
}
