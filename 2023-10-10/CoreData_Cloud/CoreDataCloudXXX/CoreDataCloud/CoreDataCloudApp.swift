//
// Created by Joey Jarosz on 10/8/23.
// Copyright (c) 2023 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

@main
struct CoreDataCloudApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PrivateContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
