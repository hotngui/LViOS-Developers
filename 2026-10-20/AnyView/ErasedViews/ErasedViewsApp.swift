import DemoKit
import SwiftUI

@main
struct ErasedViewsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .erased) { store in
                DashboardView(store: store)
            }
        }
    }
}
