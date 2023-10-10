//
// Created by Joey Jarosz on 10/8/23.
// Copyright (c) 2023 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.lastName, ascending: true)],
        animation: .default)
    
    private var items: FetchedResults<Item>

    @State private var isEditorOpen = false

    var body: some View {
        TabView {
            PublicContentView()
                .tabItem {
                    Label("Public", systemImage: "cloud")
                }
            PrivateContentView()
                .tabItem {
                    Label("Private", systemImage: "cloud.fill")
                }
        }
    }

    // MARK: - Private Methods
    
}

#if DEBUG
#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
#endif
