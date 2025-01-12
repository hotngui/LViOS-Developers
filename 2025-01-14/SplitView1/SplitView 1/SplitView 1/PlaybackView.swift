//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct PlaybackView: View {
    let item: Item?
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "music.note")
                Text("Chairs")
                Image(systemName: "music.note")
            }
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(.purple)
            
            VStack {
                if let item {
                    // Demonstrates how you let SwiftUI which view first best
                    // in the current environment...
                    ViewThatFits(in: .horizontal) {
                        HorizontalAlbumView(name: item.name)
                        VerticalAlbumView(name: item.name)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Progress()
                            .padding(.horizontal)

                        VStack {
                            Button("Button 1") {
                                print("Button 1 tapped")
                            }
                            Button("Button 2") {
                                print("Button 1 tapped")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.extraLarge)
                    }
                    .padding()

                    Spacer()
                } else {
                    Spacer()
                    Text("Please select an item")
                    Spacer()
                }
            }
            
            Spacer()
        }
    }
}

fileprivate struct HorizontalAlbumView: View {
    let name: String
    
    var body: some View {
        HStack {
            AlbumView()
            
            Text("\(name)")
                .font(.title)
        }
        .padding()
    }
}

fileprivate struct VerticalAlbumView: View {
    let name: String
    
    var body: some View {
        VStack {
            AlbumView()

            Text("\(name)")
                .font(.title)
        }
        .padding()
    }
}

#Preview("Portrait Empty", traits: .portrait) {
    PlaybackView(item: nil)
}

#Preview("Portrait", traits: .portrait) {
    PlaybackView(item: SampleData.items[0])
}

#Preview("Landscape", traits: .landscapeLeft) {
    PlaybackView(item: SampleData.items[0])
}
