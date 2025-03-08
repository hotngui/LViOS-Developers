//
// Created by Joey Jarosz on 3/3/25.
// Copyright (c) 2025 Joey Jarosz. All rights reserved.
//

import SwiftUI

/// A view that provides the main navigation interface for the PersonsDataApp.
///
/// `ContentView` serves as the root view of the application, implementing a tab-based
/// navigation system that allows users to switch between different main sections of the app.
/// The view contains two primary navigation areas:
///
/// - A persons list tab that displays a collection of person entries
/// - A secondary tab showing alien-related content
///
/// ## Topics
///
/// ### Navigation
/// - ``PersonsListView``
/// - ``AliensListView``
///
/// ## Example
/// ```swift
/// ContentView()
///     .environmentObject(YourDataModel()) // If needed
/// ```

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                PersonsListView()
            }
            .tabItem {
                Label("Persons", systemImage: "person.2")
            }
            
            NavigationStack {
                AliensListView()
            }
            .tabItem {
                Label("Aliens", systemImage: "figure.fall")
            }
        }
    }
}

#Preview("With Data") {
    ContentView()
}

#Preview("With Error") {
    ContentView()
}
