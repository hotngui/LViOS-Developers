//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

@main
struct WatchOSDemo2_Watch_AppApp: App {
    @StateObject var currentSelection = Selection()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(currentSelection)
        }
    }
}
