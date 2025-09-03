//
// Created by Joey Jarosz on 8/10/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import UserNotifications

/// A lightweight façade over UNUserNotificationCenter for requesting
/// authorization, scheduling local notifications, and managing pending and
/// delivered notifications.
///
/// Use a single shared instance of this observable object with SwiftUI by
/// injecting it into the environment from your `App` entry point.
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    /// Current authorization status for local notifications.
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    /// Snapshot of pending notification requests scheduled by the app.
    @Published private(set) var pendingRequests: [UNNotificationRequest] = []

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Task { await self.refreshAuthorizationStatus() }
        Task { await self.refreshPendingRequests() }
    }

    /// Requests notification authorization from the user.
    ///
    /// - Parameter options: Authorization options to request. Defaults to alerts, sounds, and badges.
    /// - Throws: An error if the system returns a failure or if permission is not granted.
    func requestAuthorization(options: UNAuthorizationOptions = [.alert, .sound, .badge]) async throws {
        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        await refreshAuthorizationStatus()
        if !granted {
            throw NSError(domain: "LocalPush", code: 1, userInfo: [NSLocalizedDescriptionKey: "Notifications permission not granted."])
        }
    }

    /// Refreshes and publishes the current authorizationStatus.
    @MainActor
    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Refreshes and publishes the current list of pendingRequests.
    @MainActor
    func refreshPendingRequests() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingRequests = requests
    }

    /// Schedules a local notification to fire after a given time interval.
    ///
    /// - Parameters:
    ///   - identifier: Optional identifier for the request. Defaults to a random UUID.
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - seconds: Time interval in seconds; values less than 1 are clamped to 1.
    ///   - repeats: Whether the notification should repeat.
    func scheduleTimeIntervalNotification(
        identifier: String = UUID().uuidString,
        title: String,
        body: String,
        seconds: TimeInterval,
        repeats: Bool = false
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await UNUserNotificationCenter.current().add(request)
        await refreshPendingRequests()
    }

    /// Schedules a local notification using calendar date components.
    ///
    /// - Parameters:
    ///   - identifier: Optional identifier for the request. Defaults to a random UUID.
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - date: The date to trigger the notification.
    ///   - repeats: Whether the notification should repeat.
    func scheduleCalendarNotification(
        identifier: String = UUID().uuidString,
        title: String,
        body: String,
        date: Date,
        repeats: Bool = false
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let dc = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: repeats)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await UNUserNotificationCenter.current().add(request)
        await refreshPendingRequests()
    }

    /// Removes all pending notification requests and refreshes published state.
    func removeAllPending() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await refreshPendingRequests()
    }

    // Using native async add(_:) from UNUserNotificationCenter.

    /// Removes all delivered notifications from Notification Center.
    func removeAllDelivered() async {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    // MARK: UNUserNotificationCenterDelegate
    /// Displays notifications as banners even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// Handles user interaction with delivered notifications.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

/// Entry point for the LocalPush example application.
@main
struct LocalPushApp: App {
    @StateObject private var notifications = NotificationManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notifications)
        }
    }
}
