//
// Created by Joey Jarosz on 11/3/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct SubFifthFiveView: View {
    init() {
        print("JOEY: SubFifthFiveView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "5.square.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.pink)
            
            Text("Sub Fifth Five")
                .font(.title)
                .padding()
        }
        .navigationTitle("Sub Fifth 5")
    }
}

#Preview {
    NavigationStack {
        SubFifthFiveView()
    }
}
