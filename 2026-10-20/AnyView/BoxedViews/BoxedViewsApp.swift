import DemoKit
import SwiftUI

@main
struct BoxedViewsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .boxed) { store in
                DashboardView(store: store)
            }
        }
    }
}
