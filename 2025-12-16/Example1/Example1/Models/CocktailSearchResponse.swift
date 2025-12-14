//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

/// Wraps the API response from TheCocktailDB search endpoint
struct CocktailSearchResponse: Codable, Sendable {
    let drinks: [Cocktail]?
}
