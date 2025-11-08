//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

var searchViewTaskCallCount = 0
var searchViewInitCallCount = 0

struct SearchView: View {
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "magnifyingglass")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Search Tab")
                        .font(.title)
                }
            }
            .padding()
            .navigationTitle("Search")
            .task {
                isLoading = true
                searchViewTaskCallCount += 1
                print("JOEY: SearchView task modifier called (count: \(searchViewTaskCallCount))")
                
                try? await Task.sleep(for: .seconds(2))
                isLoading = false
            }
        }
    }
    
    init() {
        searchViewInitCallCount += 1
        print("JOEY: Initializing Search View (count: \(searchViewInitCallCount))")
    }
}

#Preview {
    SearchView()
}
