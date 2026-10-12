import SwiftUI

/// The toolbar menu: intensity, tick rate, container, Live on/off, Reset dashboard, and a line about this variant.
struct SettingsMenu: View {
    @Bindable var settings: DemoSettings
    let store: DashboardStore
    /// Set to true to show the variant's explanation; `DemoShell` owns the alert.
    @Binding var showsExplanation: Bool

    var body: some View {
        Menu("Demo settings", systemImage: "gearshape") {
            Picker("Intensity", selection: $settings.intensity) {
                ForEach(Intensity.allCases) { level in
                    Text(level.title)
                        .tag(level)
                }
            }
            .pickerStyle(.menu)
            Picker("Tick rate", selection: $settings.tickRate) {
                ForEach(TickRate.allCases) { rate in
                    Text(rate.title)
                        .tag(rate)
                }
            }
            .pickerStyle(.menu)
            Picker("Container", selection: $settings.containerStyle) {
                ForEach(ContainerStyle.allCases) { style in
                    Text(style.title)
                        .tag(style)
                }
            }
            .pickerStyle(.menu)
            Toggle("Live updates", isOn: $settings.liveUpdatesEnabled)
            Button("Reset dashboard", systemImage: "arrow.counterclockwise") {
                store.reset()
            }
            Button("About this app", systemImage: "info.circle") {
                showsExplanation = true
            }
        }
    }
}
