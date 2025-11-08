//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

var homeViewTaskCallCount = 0
var homeViewInitCallCount = 0

struct HomeView: View {
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "house.fill")
                        .imageScale(.large)
                        .foregroundStyle(.tint)
                    Text("Home Tab")
                        .font(.title)
                }
            }
            .padding()
            .navigationTitle("Home")
            .task {
                isLoading = true
                homeViewTaskCallCount += 1
                print("JOEY: HomeView task modifier called (count: \(homeViewTaskCallCount))")
                
                try? await Task.sleep(for: .seconds(2))
                isLoading = false
            }
        }
    }
    
    init() {
        homeViewInitCallCount += 1
        print("JOEY: Initializing Home View (count: \(homeViewInitCallCount))")
    }
}

#Preview {
    HomeView()
}
