//
// ContentView.swift
// Created by Joey Jarosz on 12/14/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// Main coordinator view for the US States Information app
struct ContentView: View {

    // MARK: - State

    @State private var viewModel = StateQueryViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Main Content
                VStack {
                    switch viewModel.queryState {
                    case .idle:
                        idleStateView

                    case .loading:
                        loadingView

                    case .success(let stateInfo):
                        StateInformationView(stateInfo: stateInfo)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale),
                                removal: .opacity
                            ))

                    case .error:
                        errorView
                    }
                }
            }
            .navigationTitle("State Explorer")
            .navigationBarTitleDisplayMode(.inline)
            
// TODO: Claude Code gave us no way to get back to do another query.
            .toolbar {
                if case .success = viewModel.queryState {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.reset()
                        } label: {
                            Label("New Search", systemImage: "magnifyingglass")
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
                if case .error = viewModel.queryState {
                    Button("Retry") {
                        Task {
                            await viewModel.retry()
                        }
                    }
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.queryState)
        }
    }

    // MARK: - View Components

    private var idleStateView: some View {
        VStack {
            Spacer()

            // App Icon/Illustration
            VStack(spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)

                Text("Discover US States")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Search for any state to learn about its capital, state bird, and state plant")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Input View
            StateInputView(viewModel: viewModel)

            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)

            Text("Searching for state information...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Loading state information")
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button {
                viewModel.reset()
            } label: {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
