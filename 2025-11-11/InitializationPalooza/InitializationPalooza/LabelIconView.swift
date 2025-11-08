//
// Created by Joey Jarosz on 11/8/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct LabelIconView: View {
    let count: Int
    @State private var opacity: Double = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Labels & Icons")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            // Icon with label pairs
            HStack(spacing: 15) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .imageScale(.large)
                Text("Favorites")
                    .font(.headline)
            }
            .opacity(opacity)
                        
            HStack(spacing: 15) {
                Image(systemName: "person.fill")
                    .foregroundStyle(.green)
                    .imageScale(.large)
                Text("Profile")
                    .font(.headline)
            }
            .opacity(opacity)
            
            Divider()
            
            // Additional info label
            Text("Value = \(count)")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task(id: count) {
            opacity = 0.0
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1.0
            }
        }
    }
    
    init(count: Int) {
        self.count = count
        
        print("JOEY: Initialized LabelIconView - started")
        Thread.sleep(forTimeInterval: 2.0)
        print("JOEY: Initialized LabelIconView - finished")
    }
}

#Preview {
    LabelIconView(count: 42)
}
