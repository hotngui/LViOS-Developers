//
// Created by Joey Jarosz on 12/16/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import UserNotifications

class Notifications {
    static func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    if granted {
                        print("Notification access granted.")
                    } else {
                        print("Notification access denied.\(String(describing: error?.localizedDescription))")
                    }
                }
                return
            case .denied:
                print("Notification access denied")
                return
            case .authorized:
                print("Notification access granted.")
                return
            default:
                return
            }
        }
    }
    
    static func createTimeIntervalLocalNotification(title: String, body: String, timeInterval: Double, identifier: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:  timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier]) // Remove previous pending notification with same identifier
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification \(content.title) added")
            }
        }
    }
}
