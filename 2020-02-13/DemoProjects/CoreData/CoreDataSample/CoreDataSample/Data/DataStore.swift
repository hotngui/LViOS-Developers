//
//  Created by Joey Jarosz on 2/11/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import CoreData

class DataStore {
    let container = NSPersistentCloudKitContainer(name: "CoreDataPlusCloudKitSample")

    init() {
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
