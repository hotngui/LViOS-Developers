//
// Created by Joey Jarosz on 8/10/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import UserNotifications

/// Demonstrates requesting authorization, scheduling, and managing local
/// notifications using ``NotificationManager``.
struct ContentView: View {
    @EnvironmentObject private var notifications: NotificationManager
    @State private var permissionError: String?
    @State private var secondsInput: String = "3"

    var body: some View {
        NavigationStack {
            Form {
                Section("Authorization") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(statusText)
                            .foregroundStyle(statusColor)
                    }
                    Button("Request Permission") {
                        Task {
                            do {
                                try await notifications.requestAuthorization()
                                permissionError = nil
                            } catch {
                                permissionError = error.localizedDescription
                            }
                        }
                    }
                    if let permissionError {
                        Text(permissionError)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section("Schedule (Time Interval)") {
                    HStack {
                        Text("Seconds")
                        TextField("Seconds", text: $secondsInput)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                    Button("Schedule in \(secondsInput)s") {
                        Task {
                            let secs = TimeInterval(secondsInput) ?? 3
                            try? await notifications.scheduleTimeIntervalNotification(
                                title: "Local Notification",
                                body: "Fired after \(Int(secs))s",
                                seconds: secs,
                                repeats: false
                            )
                        }
                    }
                }

                Section("Manage") {
                    Button("Remove All Pending") {
                        Task { await notifications.removeAllPending() }
                    }
                    Button("Remove All Delivered") {
                        Task { await notifications.removeAllDelivered() }
                    }
                    NavigationLink("View Pending Requests") {
                        PendingListView()
                    }
                }
            }
            .navigationTitle("Local Push")
            .task { await notifications.refreshPendingRequests() }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationManager())
}

private extension ContentView {
    var statusText: String {
        switch notifications.authorizationStatus {
        case .notDetermined: return "not determined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        @unknown default: return "unknown"
        }
    }
    var statusColor: Color {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .secondary
        }
    }
}

/// Displays a list of the app's pending notification requests.
struct PendingListView: View {
    @EnvironmentObject private var notifications: NotificationManager
    var body: some View {
        List(notifications.pendingRequests, id: \.identifier) { req in
            VStack(alignment: .leading) {
                Text(req.content.title.isEmpty ? req.identifier : req.content.title)
                    .font(.headline)
                if !req.content.body.isEmpty {
                    Text(req.content.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let trigger = req.trigger {
                    Text(triggerDescription(trigger))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Pending")
        .task { await notifications.refreshPendingRequests() }
    }

    private func triggerDescription(_ trigger: UNNotificationTrigger) -> String {
        switch trigger {
        case let t as UNTimeIntervalNotificationTrigger:
            return "TimeInterval: \(Int(t.timeInterval))s repeats=\(t.repeats)"
        case let t as UNCalendarNotificationTrigger:
            if let next = t.nextTriggerDate() {
                return "Calendar: \(next.formatted()) repeats=\(t.repeats)"
            } else {
                return "Calendar repeats=\(t.repeats)"
            }
        default:
            return "Trigger"
        }
    }
}
