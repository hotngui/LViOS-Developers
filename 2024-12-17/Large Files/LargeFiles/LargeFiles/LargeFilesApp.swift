//
// Created by Joey Jarosz on 12/7/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

@main
struct LargeFilesApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var fileHandler = FileHandler()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(fileHandler)
        }
    }
}

//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
//        print("identifier: \(identifier)")
//        Notifications.createTimeIntervalLocalNotification(title: "Title", body: "Body \(identifier)", timeInterval: 2.0, identifier: identifier)
//    }
//}
