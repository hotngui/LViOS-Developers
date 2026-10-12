/// The five kinds of card on the dashboard. Ids cycle through them in this order, so a fifth of the cards are sparklines.
public enum CardKind: String, CaseIterable, Sendable {
    case stat, gauge, toggle, sparkline, pulse
}
