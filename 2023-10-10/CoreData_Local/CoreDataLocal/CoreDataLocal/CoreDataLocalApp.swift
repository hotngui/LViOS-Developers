//
// Created by Joey Jarosz on 10/1/23.
// 
//

import SwiftUI

@main
struct CoreDataLocalApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
