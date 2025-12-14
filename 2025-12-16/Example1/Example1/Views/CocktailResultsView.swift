//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// Sheet modal that displays cocktail search results
struct CocktailResultsView: View {
    let cocktails: [Cocktail]
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cocktails) { cocktail in
                        CocktailCardView(cocktail: cocktail)
                    }
                }
                .padding()
            }
            .navigationTitle("Search Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CocktailResultsView(
        cocktails: [
            Cocktail(
                idDrink: "11007",
                strDrink: "Margarita",
                strCategory: "Ordinary Drink",
                strInstructions: "Rub the rim of the glass with the lime slice to make the salt stick to it.",
                strDrinkThumb: "https://www.thecocktaildb.com/images/media/drink/5noda61589575158.jpg",
                strGlass: "Cocktail glass",
                strAlcoholic: "Alcoholic"
            ),
            Cocktail(
                idDrink: "11008",
                strDrink: "Blue Margarita",
                strCategory: "Ordinary Drink",
                strInstructions: "Rub rim of cocktail glass with lime juice.",
                strDrinkThumb: "https://www.thecocktaildb.com/images/media/drink/bry4qh1582751040.jpg",
                strGlass: "Cocktail glass",
                strAlcoholic: "Alcoholic"
            )
        ],
        onDismiss: {}
    )
}
