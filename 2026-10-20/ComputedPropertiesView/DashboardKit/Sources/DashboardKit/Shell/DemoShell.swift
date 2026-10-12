import SwiftUI

/// The shared root of both demo apps: the start screen, navigation to the dashboard, the settings menu, the
/// frame-meter HUD, and data loading. Each app passes in only its own `DashboardView`.
public struct DemoShell<Dashboard: View>: View {
    private let variant: AppVariant
    private let dashboard: ([AccountTransaction], Int) -> Dashboard

    @State private var settings = DemoSettings()
    @State private var store = TransactionStore()
    @State private var path: [DashboardRoute] = []
    /// The HUD's measured height, reserved at the bottom of both screens so it never covers content.
    @State private var hudHeight: CGFloat = 0

    /// - Parameter dashboard: Builds the dashboard from the transactions and the Recent-list row limit.
    public init(variant: AppVariant, @ViewBuilder dashboard: @escaping ([AccountTransaction], Int) -> Dashboard) {
        self.variant = variant
        self.dashboard = dashboard
    }

    public var body: some View {
        NavigationStack(path: $path) {
            StartScreen(variant: variant, intensity: settings.intensity, isReady: isDataReady, open: openDashboard)
                .safeAreaPadding(.bottom, hudHeight)
                .settingsToolbar(settings)
                .navigationDestination(for: DashboardRoute.self) { _ in
                    Group {
                        if let intensity = store.loadedIntensity, !store.isLoading {
                            dashboard(store.transactions, intensity.recentRowLimit)
                        } else {
                            ProgressView("Generating transactions…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .safeAreaPadding(.bottom, hudHeight)
                    .navigationTitle("Dashboard")
                    .settingsToolbar(settings)
                }
        }
        .overlay(alignment: .bottom) {
            // One shared HUD for both screens, so its frame clock and stats keep running through navigation.
            FrameMeterView(variant: variant, intensity: settings.intensity, liveUpdates: settings.liveUpdatesEnabled)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    hudHeight = height
                }
        }
        .environment(\.showsEvaluationBadges, settings.showsEvaluationBadges)
        .environment(\.evaluationBadgeResetGeneration, settings.badgeResetGeneration)
        .environment(\.liveUpdatesEnabled, settings.liveUpdatesEnabled)
        .environment(\.calendar, DemoClock.calendar)
        .environment(\.timeZone, DemoClock.calendar.timeZone)
        .task(id: settings.intensity) {
            await store.load(settings.intensity)
        }
    }

    private var isDataReady: Bool {
        store.loadedIntensity == settings.intensity && !store.isLoading
    }

    /// Opens the dashboard, timing it from this tap until the dashboard's first frame (the slide-in isn't included).
    private func openDashboard() {
        guard path.isEmpty else { return }
        InteractionTimer.shared.begin(.openDashboard)
        path.append(DashboardRoute())
    }
}
