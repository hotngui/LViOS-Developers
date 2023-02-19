//
// Created by Joey Jarosz on 1/14/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import AppIntents
import SwiftUI


@main
struct SimpleAppShortcutsApp: App {
    var dataModel = DataModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataModel: dataModel)
        }
    }
}


