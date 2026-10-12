import SwiftUI

/// The toolbar menu: intensity, re-evaluation badges, counter reset, and the known-stall check for the HUD.
struct SettingsMenu: View {
    @Bindable var settings: DemoSettings

    var body: some View {
        Menu("Demo settings", systemImage: "gearshape") {
            Picker("Intensity", selection: $settings.intensity) {
                ForEach(Intensity.allCases) { level in
                    Text(level.title)
                        .tag(level)
                }
            }
            .pickerStyle(.menu)
            Toggle("Show re-evaluations", isOn: $settings.showsEvaluationBadges)
            Toggle("Live updates", isOn: $settings.liveUpdatesEnabled)
            Button("Reset body-run counts", systemImage: "arrow.counterclockwise") {
                settings.resetBodyRunCounts()
            }
            Button("Simulate a 100 ms stall", systemImage: "tortoise") {
                MainThreadStall.run(for: .milliseconds(100))
            }
        }
    }
}
