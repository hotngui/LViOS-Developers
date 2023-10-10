//
// Created by Joey Jarosz on 10/9/23.
// Copyright (c) 2023 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct SwiftDataCloudTestApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
