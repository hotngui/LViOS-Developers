//
// Created by Joey Jarosz on 12/7/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

@main
struct LargeFilesApp: App {
    @State var fileHandler = FileHandler()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(fileHandler)
        }
    }
}
