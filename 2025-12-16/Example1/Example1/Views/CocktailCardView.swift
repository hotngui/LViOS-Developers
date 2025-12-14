//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import Kingfisher

/// Displays a single cocktail card with image and details
struct CocktailCardView: View {
    let cocktail: Cocktail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Cocktail Image
            if let imageURL = cocktail.thumbnailURL {
                KFImage(imageURL)
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay {
                                ProgressView()
                            }
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            // Cocktail Details
            VStack(alignment: .leading, spacing: 8) {
                Text(cocktail.name)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack {
                    Label(cocktail.category, systemImage: "tag")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Label(cocktail.alcoholic, systemImage: "drop")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Label(cocktail.glassType, systemImage: "wineglass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                Text("Instructions")
                    .font(.headline)
                    .padding(.top, 4)

                Text(cocktail.instructions)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ScrollView {
        CocktailCardView(cocktail: Cocktail(
            idDrink: "11007",
            strDrink: "Margarita",
            strCategory: "Ordinary Drink",
            strInstructions: "Rub the rim of the glass with the lime slice to make the salt stick to it. Take care to moisten only the outer rim and sprinkle the salt on it. The salt should present to the lips of the imbiber and never mix into the cocktail. Shake the other ingredients with ice, then carefully pour into the glass.",
            strDrinkThumb: "https://www.thecocktaildb.com/images/media/drink/5noda61589575158.jpg",
            strGlass: "Cocktail glass",
            strAlcoholic: "Alcoholic"
        ))
        .padding()
    }
}
