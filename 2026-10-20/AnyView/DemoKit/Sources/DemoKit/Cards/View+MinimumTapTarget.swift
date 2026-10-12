import SwiftUI

extension View {
    /// Pads an icon-only control's hit area up to the Human Interface Guidelines' 44 pt minimum (WCAG 2.5.8 asks for
    /// at least 24 pt), without changing how the glyph looks.
    public func minimumTapTarget() -> some View {
        frame(minWidth: 44, minHeight: 44)
            .contentShape(.rect)
    }
}
