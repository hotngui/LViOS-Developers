//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var counter = ObservableCounter()
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }
            
            Tab("Search", systemImage: "magnifyingglass") {
                SearchView()
            }
            
            Tab("Profile", systemImage: "person") {
                ProfileView()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button("Count: \(counter.count)") {
                counter.count += 1
            }
            .padding()
        }
    }
    
    init() {
        print("JOEY: Initializing ContentView")
    }
}

#Preview {
    ContentView()
}
