import DashboardKit
import SwiftUI

@main
struct ComputedDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .computed) { transactions, rowLimit in
                DashboardView(transactions: transactions, rowLimit: rowLimit)
            }
        }
    }
}
