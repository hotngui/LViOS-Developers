//
// Created by Joey Jarosz on 11/2/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct FourthView: View {
    init() {
        print("JOEY: FourthView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "4.circle.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            Text("Fourth View")
                .font(.title)
                .padding()
        }
        .navigationTitle("Fourth")
    }
}

#Preview {
    NavigationStack {
        FourthView()
    }
}
