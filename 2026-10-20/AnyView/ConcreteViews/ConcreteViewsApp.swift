import DemoKit
import SwiftUI

@main
struct ConcreteViewsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .concrete) { store in
                DashboardView(store: store)
            }
        }
    }
}
