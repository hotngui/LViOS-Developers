/// Counts card appearances (`onAppear`). The Erased app re-creates every card on every tick, so its count climbs by the
/// card count per tick; Boxed and Concrete stop at the card count.
///
/// Deliberately *not* `@Observable`: cards record from `onAppear` and the HUD polls it every frame, and neither must
/// trigger another update.
@MainActor
public final class AppearanceCounter {
    public static let shared = AppearanceCounter()

    public private(set) var count = 0

    public init() {}

    public func record() {
        count += 1
    }

    public func reset() {
        count = 0
    }
}
