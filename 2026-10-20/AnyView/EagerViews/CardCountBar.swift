import DemoKit
import SwiftUI

/// The app's one option: how many cards the stack holds. Always on screen, so every video frame shows the choice.
struct CardCountBar: View {
    @Binding var selection: CardCount

    var body: some View {
        Picker("Cards", selection: $selection) {
            ForEach(CardCount.allCases) { count in
                Text(count.rawValue, format: .number)
                    .tag(count)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .background(.bar)
    }
}
