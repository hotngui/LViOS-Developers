//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

/// Custom errors that can occur during cocktail search operations
enum CocktailServiceError: LocalizedError, Sendable {
    case networkError(String)
    case decodingError
    case noResults
    case invalidSearchTerm

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingError:
            return "Failed to decode the response. Please try again."
        case .noResults:
            return "No cocktails found. Try a different search term."
        case .invalidSearchTerm:
            return "Please enter a valid search term."
        }
    }
}

/// Service for interacting with TheCocktailDB API
actor CocktailService {
    private let baseURL = "https://www.thecocktaildb.com/api/json/v1/1/search.php"

    /// Searches for cocktails by name using the API
    /// - Parameter searchTerm: The cocktail name to search for
    /// - Returns: Array of matching cocktails
    /// - Throws: CocktailServiceError for various failure cases
    func searchCocktails(by searchTerm: String) async throws -> [Cocktail] {
        // Validate search term
        let trimmedTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else {
            throw CocktailServiceError.invalidSearchTerm
        }

        // Construct URL
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw CocktailServiceError.networkError("Invalid base URL")
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "s", value: trimmedTerm)
        ]

        guard let url = urlComponents.url else {
            throw CocktailServiceError.networkError("Failed to construct URL")
        }

        // Perform network request
        let (data, response) = try await URLSession.shared.data(from: url)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CocktailServiceError.networkError("Invalid response from server")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw CocktailServiceError.networkError("Server returned status code \(httpResponse.statusCode)")
        }

        // Decode response
        do {
            let searchResponse = try JSONDecoder().decode(CocktailSearchResponse.self, from: data)

            // Check if results exist
            guard let drinks = searchResponse.drinks, !drinks.isEmpty else {
                throw CocktailServiceError.noResults
            }

            return drinks
        } catch is DecodingError {
            throw CocktailServiceError.decodingError
        } catch {
            throw error
        }
    }
}
