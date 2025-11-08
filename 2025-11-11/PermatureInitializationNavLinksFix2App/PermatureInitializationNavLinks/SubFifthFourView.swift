//
// Created by Joey Jarosz on 11/3/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct SubFifthFourView: View {
    init() {
        print("JOEY: SubFifthFourView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "4.square.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.purple)
            
            Text("Sub Fifth Four")
                .font(.title)
                .padding()
        }
        .navigationTitle("Sub Fifth 4")
    }
}

#Preview {
    NavigationStack {
        SubFifthFourView()
    }
}
