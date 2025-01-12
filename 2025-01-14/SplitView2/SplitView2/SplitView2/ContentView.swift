//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import MapKit

// This is a simple example of how you can represent completely different user
// interface based on the size class of the device.
//
struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .compact {
            CompactView()
        } else {
            RegularView()
        }
    }
}

#Preview {
    ContentView()
}
