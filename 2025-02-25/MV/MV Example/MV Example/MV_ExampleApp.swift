//
// Created by Joey Jarosz on 2/16/25.
// Copyright (c) 2025 ___ORGANIZATIONNAME___. All rights reserved.
//

import SwiftUI

@main
struct MV_ExampleApp: App {
    @State var items = MyData.sampleData
    
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Editor", systemImage: "person") {
                    EditorView(items: items)
                }
                Tab("Reference", systemImage: "person.circle") {
                    ReferenceView(items: items)
                }
            }
        }
    }
}
