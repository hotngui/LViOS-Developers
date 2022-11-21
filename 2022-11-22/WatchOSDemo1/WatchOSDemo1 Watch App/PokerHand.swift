//
// Created by Joey Jarosz on 11/21/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// This is our "data" object... One could argue that the "color" does not belong here in a data object since the _Color_ object is specific to _SwiftUI_
///
struct PokerHand: Identifiable {
    let id = UUID()
    let text: String
    let imageName: String
    let color: Color
}

