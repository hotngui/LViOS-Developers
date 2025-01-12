//
// Created by Joey Jarosz on 1/12/25.
// Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            Text("This is running on an ")
                .font(.largeTitle) +
            Text("iPad")
                .font(.largeTitle)
                .fontWeight(.semibold)

        } else {
            Text("This is running on an ")
                .font(.title) +
            Text("iPhone")
                .font(.title)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    ContentView()
}
