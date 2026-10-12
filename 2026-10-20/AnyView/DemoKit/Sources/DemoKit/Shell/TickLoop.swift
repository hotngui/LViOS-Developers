/// The `task(id:)` key for the tick loop: the loop restarts whenever Live or the rate changes.
struct TickLoop: Equatable {
    let isLive: Bool
    let rate: TickRate
}
