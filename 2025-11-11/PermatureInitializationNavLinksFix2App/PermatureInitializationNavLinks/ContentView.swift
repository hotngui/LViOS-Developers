//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    enum Destination {
        case one, two, three, four, five
    }

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    NavigationLazyView(FirstView())
                } label: {
                    Text("First View")
                }
                
                NavigationLink {
                    NavigationLazyView(SecondView())
                } label: {
                    Text("Second View")
                }
                
                NavigationLink {
                    NavigationLazyView(ThirdView())
                } label: {
                    Text("Third View")
                }
                
                NavigationLink {
                    NavigationLazyView(FourthView())
                } label: {
                    Text("Fourth View")
                }
                
                NavigationLink {
                    NavigationLazyView(FifthView())
                } label: {
                    Text("Fifth View")
                }
                
            }
            .navigationTitle("Main Menu")
        }
    }
}

// MARK: - Helpers

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    
    var body: Content {
        build()
    }
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
