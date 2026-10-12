import DemoKit
import SwiftUI

@main
struct NestedViewsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .nested) { store in
                DashboardView(store: store)
            }
        }
    }
}
