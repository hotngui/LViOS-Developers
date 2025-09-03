# ``LocalPush``

A minimal SwiftUI app demonstrating iOS local notifications: requesting permission, scheduling, listing, and clearing.

## Overview

LocalPush shows how to:

- Request user authorization for notifications
- Schedule notifications using time interval or calendar triggers
- Show notifications while the app is in the foreground
- Remove pending and delivered notifications

### Key Types

- ``NotificationManager``: Observable object that wraps UNUserNotificationCenter.
- ``ContentView``: UI for requesting permission and scheduling notifications.
- ``PendingListView``: UI for inspecting pending notification requests.

## Topics

### Managing Notifications

- ``NotificationManager``
- ``NotificationManager/requestAuthorization(options:)``
- ``NotificationManager/scheduleTimeIntervalNotification(identifier:title:body:seconds:repeats:)``
- ``NotificationManager/scheduleCalendarNotification(identifier:title:body:date:repeats:)``
- ``NotificationManager/removeAllPending()``
- ``NotificationManager/removeAllDelivered()``
