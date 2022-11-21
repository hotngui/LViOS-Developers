//
// Created by Joey Jarosz on 11/11/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// This is the primary screen of the app...
///
struct ContentView: View {
    let pokerHands: [PokerHand]
    
    var body: some View {
        List {
            ForEach(pokerHands) { hand in
                HandView(imageName: hand.imageName, text: hand.text, color: hand.color)
            }
        }
        .padding()
    }
    
    init() {
        pokerHands = [
            PokerHand(text: "Royal Flush", imageName: "suit.heart.fill", color: .red),
            PokerHand(text: "Straight Flush", imageName: "suit.club.fill", color: .green),
            PokerHand(text: "Four of a Kind", imageName: "suit.diamond.fill", color: .blue),
            PokerHand(text: "Full House", imageName: "suit.spade.fill", color: .white),
            PokerHand(text: "Flush", imageName: "suit.heart.fill", color: .red),
            PokerHand(text: "Straight", imageName: "suit.club.fill", color: .green),
            PokerHand(text: "Three of a Kind", imageName: "suit.diamond.fill", color: .blue),
            PokerHand(text: "Two Pair", imageName: "suit.spade.fill", color: .white),
            PokerHand(text: "Pair", imageName: "suit.heart.fill", color: .red),
            PokerHand(text: "High Card", imageName: "suit.club.fill", color: .green)
        ]
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("Apple Watch Series 8 (41mm)")
                .previewDisplayName("41mm")
            ContentView()
                .previewDevice("Apple Watch Ultra (49mm)")
                .previewDisplayName("Ultra")
        }
    }
}
#endif
