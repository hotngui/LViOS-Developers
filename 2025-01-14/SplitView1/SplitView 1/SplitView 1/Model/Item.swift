//
// Created by Joey Jarosz on 1/11/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

// A extremely simple piece of data for this sample that represents the name of a song...
//
struct Item: Identifiable, Hashable {
    var id = UUID()
    var name: String
}
