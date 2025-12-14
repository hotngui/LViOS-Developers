//
// StateInputView.swift
// Created by Joey Jarosz on 12/14/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

/// Input view providing both text and voice input options for state queries
struct StateInputView: View {

    // MARK: - Properties

    @Bindable var viewModel: StateQueryViewModel
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("US State Information")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            // Subtitle
            Text("Ask about any US state")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Search Field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField("Enter a state name...", text: $viewModel.searchText)
                    .focused($isTextFieldFocused)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch()
                    }
                    .accessibilityLabel("State search field")
                    .accessibilityHint("Enter a US state name to search for information")

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        viewModel.reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Action Buttons
            HStack(spacing: 12) {
                // Voice Input Button
                Button {
                    Task {
                        if viewModel.speechRecognitionService.isRecording {
                            await viewModel.stopVoiceInput()
                        } else {
                            await viewModel.startVoiceInput()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.speechRecognitionService.isRecording ? "stop.circle.fill" : "mic.fill")
                        Text(viewModel.speechRecognitionService.isRecording ? "Stop" : "Voice")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.speechRecognitionService.isRecording ? Color.red : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel(viewModel.speechRecognitionService.isRecording ? "Stop voice recording" : "Start voice recording")
                .accessibilityHint("Use voice to search for a US state")

                // Search Button
                Button {
                    performSearch()
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.searchText.isEmpty)
                .opacity(viewModel.searchText.isEmpty ? 0.5 : 1.0)
                .accessibilityLabel("Search for state")
                .accessibilityHint("Tap to search for information about the entered state")
            }

            // Voice Recognition Feedback
            if viewModel.speechRecognitionService.isRecording {
                HStack {
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative.reversing)
                        .foregroundStyle(.red)

                    Text(viewModel.speechRecognitionService.recognizedText.isEmpty ?
                         "Listening..." : viewModel.speechRecognitionService.recognizedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityLabel("Voice recognition: \(viewModel.speechRecognitionService.recognizedText.isEmpty ? "Listening" : viewModel.speechRecognitionService.recognizedText)")
            }

            // Example Queries
            VStack(alignment: .leading, spacing: 8) {
                Text("Examples:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    exampleChip("California")
                    exampleChip("Texas")
                    exampleChip("New York")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .animation(.easeInOut, value: viewModel.speechRecognitionService.isRecording)
    }

    // MARK: - Helper Views

    private func exampleChip(_ text: String) -> some View {
        Button {
            viewModel.searchText = text
        } label: {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        .accessibilityLabel("Example: \(text)")
        .accessibilityHint("Tap to search for \(text)")
    }

    // MARK: - Helper Methods

    private func performSearch() {
        isTextFieldFocused = false
        Task {
            await viewModel.performQuery(viewModel.searchText)
        }
    }
}

// MARK: - Preview

#Preview {
    StateInputView(viewModel: StateQueryViewModel())
}
