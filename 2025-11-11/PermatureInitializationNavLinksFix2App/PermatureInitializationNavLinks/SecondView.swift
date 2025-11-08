//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct SecondView: View {
    init() {
        print("JOEY: SecondView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "2.circle.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Second View")
                .font(.title)
                .padding()
        }
        .navigationTitle("Second")
    }
}

#Preview {
    NavigationStack {
        SecondView()
    }
}
