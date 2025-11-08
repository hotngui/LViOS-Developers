//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var counter = ObservableCounter()

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("First View") {
                    FirstView()
                }
                
                NavigationLink("Second View") {
                    SecondView()
                }
                
                NavigationLink("Third View") {
                    ThirdView()
                }
                
                NavigationLink("Fourth View") {
                    FourthView()
                }
                
                NavigationLink("Fifth View") {
                    FifthView()
                }
            }
            .navigationTitle("Main Menu")
        }
        .overlay(alignment: .topTrailing) {
            Button("Count: \(counter.count)") {
                Task.detached {
                    try? await Task.sleep(for: .seconds(2.0))
                    await MainActor.run {
                        print("JOEY: Updating counter value...")
                        counter.count += 1
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
