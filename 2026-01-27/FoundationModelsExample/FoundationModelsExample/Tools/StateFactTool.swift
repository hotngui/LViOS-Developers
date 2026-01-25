//
// Created by Joey Jarosz on 1/19/26.
// Copyright (c) 2026 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import FoundationModels

struct StateFactTool: Tool {
    let name = "findFavoriteStateColor"
    let description = "find state's favorite color"

    @Generable
    struct Arguments {
        @Guide(description: "The state to find the favorite color of")
        let state: String
    }

    func call(arguments: Arguments) async throws -> [StateFact] {
        var facts: [StateFact] = []

        let stateName = arguments.state
        
        if let color = await favoriteColors[stateName] {
            let colorFact = StateFact(name: "State Color", details: color)
            facts.append(colorFact)
        }
        
        if stateName == "Nevada" {
            let flowerFact = StateFact(name: "State Flower", details: "Orange traffic cone")
            facts.append(flowerFact)
        }

        print("StateFactTool: Generated \(facts.count) facts")

        return facts // GeneratedContent(properties: ["facts": facts])
    }
}

let favoriteColors: [String: String] = [
    "Alabama": "Crimson",
    "Alaska": "Ice Blue",
    "Arizona": "Copper",
    "Arkansas": "Forest Green",
    "California": "Gold",
    "Colorado": "Sky Blue",
    "Connecticut": "Navy",
    "Delaware": "Teal",
    "Florida": "Orange",
    "Georgia": "Peach",
    "Hawaii": "Turquoise",
    "Idaho": "Silver",
    "Illinois": "Royal Blue",
    "Indiana": "Scarlet",
    "Iowa": "Amber",
    "Kansas": "Sunflower Yellow",
    "Kentucky": "Emerald",
    "Louisiana": "Purple",
    "Maine": "Pine Green",
    "Maryland": "Burgundy",
    "Massachusetts": "Maroon",
    "Michigan": "Maize",
    "Minnesota": "Violet",
    "Mississippi": "Indigo",
    "Missouri": "Rose",
    "Montana": "Steel Gray",
    "Nebraska": "Wheat",
    "Nevada": "Sage",
    "New Hampshire": "Granite Gray",
    "New Jersey": "Tan",
    "New Mexico": "Terracotta",
    "New York": "Slate",
    "North Carolina": "Carolina Blue",
    "North Dakota": "Rust",
    "Ohio": "Olive",
    "Oklahoma": "Burnt Orange",
    "Oregon": "Moss Green",
    "Pennsylvania": "Charcoal",
    "Rhode Island": "Aquamarine",
    "South Carolina": "Coral",
    "South Dakota": "Honey",
    "Tennessee": "Vermillion",
    "Texas": "Burnt Sienna",
    "Utah": "Salmon",
    "Vermont": "Jade",
    "Virginia": "Cobalt",
    "Washington": "Evergreen",
    "West Virginia": "Coal Black",
    "Wisconsin": "Cherry",
    "Wyoming": "Adobe"
]

