//
// Created by Joey Jarosz on 2/22/25.
// Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI
import SwiftData

@main
struct MVVM_ExampleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MyData.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container =  try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Check if we've already loaded sample data
            if !UserDefaults.standard.bool(forKey: "hasPreloadedData") {
                // Insert sample data
                let context = container.mainContext
                
                for item in MyData.sampleData {
                    context.insert(item)
                }
                
                // Mark that we've loaded the data
                UserDefaults.standard.set(true, forKey: "hasPreloadedData")
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        @State var viewModel = ViewModel(modelContext: sharedModelContainer.mainContext)
        
        WindowGroup {
            TabView {
                Tab("Editor", systemImage: "person") {
                    EditorView(viewModel: viewModel)
                }
                Tab("Reference", systemImage: "person.circle") {
                    ReferenceView(viewModel: viewModel)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
