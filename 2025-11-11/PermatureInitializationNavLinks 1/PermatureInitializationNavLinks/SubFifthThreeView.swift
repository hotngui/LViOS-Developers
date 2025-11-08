//
// Created by Joey Jarosz on 11/3/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct SubFifthThreeView: View {
    init() {
        print("JOEY: SubFifthThreeView initialized")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "3.square.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Sub Fifth Three")
                .font(.title)
                .padding()
        }
        .navigationTitle("Sub Fifth 3")
    }
}

#Preview {
    NavigationStack {
        SubFifthThreeView()
    }
}
