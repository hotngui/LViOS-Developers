import SwiftUI

extension View {
    /// Adds the demo settings menu (intensity, badges, counts reset, stall) to this screen's toolbar.
    func settingsToolbar(_ settings: DemoSettings) -> some View {
        toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsMenu(settings: settings)
            }
        }
    }
}
