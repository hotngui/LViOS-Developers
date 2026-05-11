import SwiftUI

@main
struct MetalExampleApp: App {
    @State private var metal = MetalContext()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(metal)
        }
    }
}
