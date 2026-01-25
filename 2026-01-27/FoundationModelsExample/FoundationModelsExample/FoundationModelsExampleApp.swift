//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

@main
struct FoundationModelsExampleApp: App {
    @State private var foundationManager = FoundationManager()

    var body: some Scene {
        WindowGroup {
            StartView()
                .environment(foundationManager)
        }
    }
}
