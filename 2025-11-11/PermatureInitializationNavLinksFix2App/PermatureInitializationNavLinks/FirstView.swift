//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct FirstView: View {
    init() {
        print("JOEY: FirstView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "1.circle.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("First View")
                .font(.title)
                .padding()
        }
        .navigationTitle("First")
    }
}

#Preview {
    NavigationStack {
        FirstView()
    }
}
