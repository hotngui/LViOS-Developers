//
// Created by Joey Jarosz on 11/3/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct SubFifthTwoView: View {
    init() {
        print("JOEY: SubFifthTwoView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "2.square.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Sub Fifth Two")
                .font(.title)
                .padding()
        }
        .navigationTitle("Sub Fifth 2")
    }
}

#Preview {
    NavigationStack {
        SubFifthTwoView()
    }
}
