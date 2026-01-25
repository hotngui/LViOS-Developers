//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

@Generable
struct StateFact: Identifiable, Equatable {
    let id = UUID()

    @Guide(description: "The name of the fact")
    let name: String

    @Guide(description: "The details of the fact")
    let details: String
}
