//
// Created by Joey Jarosz on 10/9/23.
// Copyright (c) 2023 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

@main
struct CoreDataCloudTestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
