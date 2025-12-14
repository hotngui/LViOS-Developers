//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

/// Represents a cocktail from TheCocktailDB API
struct Cocktail: Codable, Identifiable, Sendable {
    let idDrink: String
    let strDrink: String
    let strCategory: String?
    let strInstructions: String?
    let strDrinkThumb: String?
    let strGlass: String?
    let strAlcoholic: String?

    var id: String { idDrink }

    var name: String { strDrink }
    var category: String { strCategory ?? "Unknown Category" }
    var instructions: String { strInstructions ?? "No instructions available" }
    var thumbnailURL: URL? {
        guard let urlString = strDrinkThumb else { return nil }
        return URL(string: urlString)
    }
    var glassType: String { strGlass ?? "Unknown Glass" }
    var alcoholic: String { strAlcoholic ?? "Unknown" }
}
