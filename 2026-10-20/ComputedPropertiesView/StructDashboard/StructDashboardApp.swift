import DashboardKit
import SwiftUI

@main
struct StructDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DemoShell(variant: .structs) { transactions, rowLimit in
                DashboardView(transactions: transactions, rowLimit: rowLimit)
            }
        }
    }
}
