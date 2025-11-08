//
// Created by Joey Jarosz on 11/8/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var counter = ObservableCounter()

    var body: some View {
        NavigationStack {
            VStack {
                LabelIconView(count: counter.count)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Count: \(counter.count)") {
                        Task.detached {
                            try? await Task.sleep(for: .seconds(1.0))
                            await MainActor.run {
                                print("JOEY: Updating counter value...")
                                counter.count += 1
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
