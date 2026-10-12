import SwiftUI

/// The shared root of every demo app: the store and settings, the Reload button and settings menu, the tick loop, the
/// container style, the empty state, and the HUD. Each app passes in only its own `DashboardView`.
public struct DemoShell<Dashboard: View>: View {
    private let variant: AppVariant
    private let dashboard: (DashboardStore) -> Dashboard

    @State private var settings = DemoSettings()
    @State private var store = DashboardStore()
    /// The HUD's measured height, reserved at the bottom of the dashboard so it never covers cards.
    @State private var hudHeight: CGFloat = 0
    @State private var showsExplanation = false

    public init(variant: AppVariant, @ViewBuilder dashboard: @escaping (DashboardStore) -> Dashboard) {
        self.variant = variant
        self.dashboard = dashboard
    }

    public var body: some View {
        NavigationStack {
            dashboard(store)
                .safeAreaPadding(.bottom, hudHeight)
                .overlay {
                    // Only after a load: before the first load the store is empty too, and that is not "removed".
                    if store.cardCount == 0, store.dataVersion > 0 {
                        ContentUnavailableView(
                            "No cards", systemImage: "rectangle.on.rectangle.slash",
                            description: Text("Every card was removed. Reset dashboard in the settings menu brings them back.")
                        )
                    }
                }
                .navigationTitle(Text(variant.name))
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Reload", systemImage: "arrow.clockwise") {
                            store.reload()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        SettingsMenu(settings: settings, store: store, showsExplanation: $showsExplanation)
                    }
                }
                .alert(Text(variant.title), isPresented: $showsExplanation) {
                    Button("OK") {}
                } message: {
                    Text(variant.explanation)
                }
        }
        .overlay(alignment: .bottom) {
            FrameMeterView(
                variant: variant, intensity: settings.intensity, tickRate: settings.tickRate,
                containerStyle: settings.containerStyle, liveUpdates: settings.liveUpdatesEnabled,
                loadedAt: store.lastLoaded, cardCount: store.cardCount
            )
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                hudHeight = height
            }
        }
        .environment(store)
        .environment(\.containerStyle, settings.containerStyle)
        .task(id: settings.intensity) {
            store.load(settings.intensity)
        }
        .task(id: TickLoop(isLive: settings.liveUpdatesEnabled, rate: settings.tickRate)) {
            await runTicks()
        }
    }

    /// Ticks the store at the selected rate until cancelled. The pause is fixed: if a tick's rebuild outlasts it, the
    /// app never idles, which is part of what the demo shows.
    private func runTicks() async {
        guard settings.liveUpdatesEnabled else { return }
        let interval = settings.tickRate.interval
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            store.tick()
        }
    }
}
