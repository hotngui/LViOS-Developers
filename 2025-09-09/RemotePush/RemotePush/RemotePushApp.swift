//
// Created by Joey Jarosz on 8/10/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import UserNotifications
import UIKit

final class PushNotificationManager: ObservableObject {
    @Published var authorizationStatusDescription: String = "Not Determined"
    @Published var deviceTokenHex: String = ""
    @Published var lastTappedPayloadText: String = ""
    @Published var registrationErrorDescription: String = ""

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatusDescription = Self.describe(status: settings.authorizationStatus)
            }
        }
    }

    func requestAuthorizationAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error {
                    self?.registrationErrorDescription = error.localizedDescription
                }
            }
            self?.refreshAuthorizationStatus()
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func handleDeviceToken(_ tokenData: Data) {
        let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
        print("APNs device token (hex): \(tokenString)")
        DispatchQueue.main.async {
            self.deviceTokenHex = tokenString
        }
    }

    func handleRegistrationError(_ error: Error) {
        DispatchQueue.main.async {
            self.registrationErrorDescription = error.localizedDescription
        }
    }

    func handleNotificationUserInfo(_ userInfo: [AnyHashable: Any], fromUserTap: Bool) {
        guard fromUserTap else { return }
        let text = Self.extractPayloadText(from: userInfo)
        DispatchQueue.main.async {
            self.lastTappedPayloadText = text
        }
    }

    private static func extractPayloadText(from userInfo: [AnyHashable: Any]) -> String {
        if let myData = userInfo["MyOwnData"] as? String {
            return myData
        }
        return "<MISSING>"
    }

    private static func describe(status: UNAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var pushManager: PushNotificationManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        pushManager?.refreshAuthorizationStatus()
        if let payload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            pushManager?.handleNotificationUserInfo(payload, fromUserTap: true)
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        pushManager?.handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        pushManager?.handleRegistrationError(error)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("[Push] User tapped notification with userInfo: \(userInfo)")
        pushManager?.handleNotificationUserInfo(userInfo, fromUserTap: true)
        completionHandler()
    }
}

@main
struct RemotePushApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pushManager: PushNotificationManager

    init() {
        let manager = PushNotificationManager()
        _pushManager = StateObject(wrappedValue: manager)
        appDelegate.pushManager = manager
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(pushManager)
        }
    }
}
