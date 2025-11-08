//
// Created by Joey Jarosz on 11/3/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct SubFifthOneView: View {
    init() {
        print("JOEY: SubFifthOneView initialized before")
        Thread.sleep(forTimeInterval: 3.0)
        print("JOEY: SubFifthOneView initialized after")
    }
    
    var body: some View {
        VStack {
            Image(systemName: "1.square.fill")
                .imageScale(.large)
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Sub Fifth One")
                .font(.title)
                .padding()
        }
        .navigationTitle("Sub Fifth 1")
    }
}

#Preview {
    NavigationStack {
        SubFifthOneView()
    }
}
