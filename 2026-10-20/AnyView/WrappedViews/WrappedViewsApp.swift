import DemoKit
import SwiftUI

@main
struct WrappedViewsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .wrapped) { store in
                DashboardView(store: store)
            }
        }
    }
}
