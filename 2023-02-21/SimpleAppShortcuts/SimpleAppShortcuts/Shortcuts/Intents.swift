//
// Created by Joey Jarosz on 1/14/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import AppIntents

// MARK: - Simplest App Intent

/// The world's simplest AppIntent that does nothing more than start up my application...
///
struct OpenAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open App"
    static var openAppWhenRun = true
    
    func perform() async throws -> some ProvidesDialog {
        return .result(dialog: "Okay, starting the application.")
    }
}

struct LatestValueIntent: AppIntent {
    static let title: LocalizedStringResource = "Latest Value"
    static var openAppWhenRun = false

    func perform() async throws -> some ReturnsValue<Double> & ProvidesDialog {
        if let latest = DataModel().newestValue() {
            return .result(value: latest, dialog: "The latest value we have is \(latest).")
        } else {
            return .result(value: -1, dialog: "Sorry, we currently have no values.")
        }
    }
}


// MARK: - App Shortcuts Provider

/// This struct defines the AppShortcuts we want to publish.
///
struct SimplestShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .blue
    
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
            AppShortcut(
                intent: OpenAppIntent(),
                phrases: [
                    "Start \(.applicationName)",
                    "Open \(.applicationName)"])
            AppShortcut(
                intent: LatestValueIntent(),
                phrases: [
                    "What's the latest value for \(.applicationName)?",
                    "For \(.applicationName) what's the newest value?"])
    }
}
