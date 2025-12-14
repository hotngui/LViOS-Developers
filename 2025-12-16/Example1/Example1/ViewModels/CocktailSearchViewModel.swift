//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/// Represents the various states of a cocktail search operation
enum SearchState: Sendable {
    case idle
    case loading
    case success([Cocktail])
    case error(String)
}

/// ViewModel managing cocktail search operations and history
@Observable
@MainActor
final class CocktailSearchViewModel {
    private let service = CocktailService()
    private let maxHistoryCount = 10

    // MARK: - Published State

    var searchState: SearchState = .idle
    var searchHistory: [String] = []
    var showResults = false

    // MARK: - Computed Properties

    var isLoading: Bool {
        if case .loading = searchState {
            return true
        }
        return false
    }

    var cocktails: [Cocktail] {
        if case .success(let drinks) = searchState {
            return drinks
        }
        return []
    }

    var errorMessage: String? {
        if case .error(let message) = searchState {
            return message
        }
        return nil
    }

    // MARK: - Initialization

    init() {
        loadSearchHistory()
    }

    // MARK: - Public Methods

    /// Performs a cocktail search for the given term
    /// - Parameter searchTerm: The cocktail name to search for
    func search(for searchTerm: String) async {
        searchState = .loading

        do {
            let cocktails = try await service.searchCocktails(by: searchTerm)
            searchState = .success(cocktails)
            addToHistory(searchTerm)
            showResults = true
        } catch let error as CocktailServiceError {
            searchState = .error(error.localizedDescription)
        } catch {
            searchState = .error("An unexpected error occurred: \(error.localizedDescription)")
        }
    }

    /// Dismisses the results sheet
    func dismissResults() {
        showResults = false
    }

    /// Resets the search state to idle
    func resetSearch() {
        searchState = .idle
    }

    // MARK: - History Management

    /// Adds a search term to the history, maintaining the last 10 searches
    /// - Parameter term: The search term to add
    private func addToHistory(_ term: String) {
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTerm.isEmpty else { return }

        // Remove existing instance if present
        searchHistory.removeAll { $0.lowercased() == trimmedTerm.lowercased() }

        // Add to the beginning
        searchHistory.insert(trimmedTerm, at: 0)

        // Limit to 10 items
        if searchHistory.count > maxHistoryCount {
            searchHistory = Array(searchHistory.prefix(maxHistoryCount))
        }

        saveSearchHistory()
    }

    /// Loads search history from UserDefaults
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "searchHistory"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            searchHistory = decoded
        }
    }

    /// Saves search history to UserDefaults
    private func saveSearchHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(encoded, forKey: "searchHistory")
        }
    }
}
