//
// Created by Joey Jarosz on 12/13/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// Main view for cocktail search with search field and history
struct CocktailSearchView: View {
    @State private var viewModel = CocktailSearchViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Section
                VStack(spacing: 16) {
                    TextField("Enter cocktail name", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            performSearch()
                        }

                    Button {
                        performSearch()
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)

                        Button {
                            performSearch()
                        } label: {
                            Text("Retry")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                // Loading Indicator
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Searching...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Search History
                    if viewModel.searchHistory.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)

                            Text("No search history")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text("Search for cocktails to get started")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List {
                            Section {
                                ForEach(viewModel.searchHistory, id: \.self) { term in
                                    Button {
                                        searchText = term
                                        performSearch()
                                    } label: {
                                        SearchHistoryRow(searchTerm: term)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                Text("Recent Searches")
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Cocktail Search")
            .sheet(isPresented: $viewModel.showResults) {
                CocktailResultsView(
                    cocktails: viewModel.cocktails,
                    onDismiss: {
                        viewModel.dismissResults()
                    }
                )
            }
        }
    }

    // MARK: - Private Methods

    private func performSearch() {
        Task {
            await viewModel.search(for: searchText)
        }
    }
}

#Preview {
    CocktailSearchView()
}
