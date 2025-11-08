//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ThirdView: View {
    init() {
        print("JOEY: ThirdView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "3.circle.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Third View")
                .font(.title)
                .padding()
        }
        .navigationTitle("Third")
    }
}

#Preview {
    NavigationStack {
        ThirdView()
    }
}
