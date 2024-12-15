//
// Created by Joey Jarosz on 11/30/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Correct", systemImage: "right.circle") {
                RightView()
            }
            Tab("Boring", systemImage: "rectangle.stack") {
                BoringView()
            }
            Tab("Wrong", systemImage: "wrongwaysign") {
                WrongView()
            }
            Tab("Grid", systemImage: "rectangle.grid.2x2") {
                GridView()
            }
        }
        .onAppear {
            print(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? "")
        }
    }
}

#Preview {
    ContentView()
}
