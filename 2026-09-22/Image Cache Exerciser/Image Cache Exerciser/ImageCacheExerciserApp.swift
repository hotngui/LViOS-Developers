//
// Created by Joey Jarosz on 9/20/26.
//

import SwiftUI

@main
struct ImageCacheExerciserApp: App {
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(settings)
        }
    }
}
