//
// Created by Joey Jarosz on 11/12/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// A simple class to represent the currently selected choice...
/// 
class Selection: ObservableObject, Equatable {
    @Published var current: String = ""
    
    static func == (lhs: Selection, rhs: Selection) -> Bool {
        return (lhs.current == rhs.current)
    }
}
