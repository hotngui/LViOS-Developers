//
// StateQueryViewModel.swift
// Created by Joey Jarosz on 12/14/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import SwiftUI

/// Main view model managing state queries and orchestrating services
@MainActor
@Observable
final class StateQueryViewModel {

    // MARK: - Published Properties

    var queryState: QueryState = .idle
    var searchText = ""
    var errorMessage: String?
    var showError = false

    // MARK: - Private Properties

    private let foundationModelsService = FoundationModelsService()
    let speechRecognitionService = SpeechRecognitionService()

    // MARK: - Public Methods

    /// Perform a state query using the Foundation Models service
    /// - Parameter query: The natural language query about a US state
    func performQuery(_ query: String) async {
        // Reset error state
        errorMessage = nil
        showError = false

        // Validate input
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            errorMessage = "Please enter a state name or question about a US state."
            showError = true
            return
        }

        // Set loading state
        queryState = .loading

        do {
            // Query the Foundation Models service
            let stateInfo = try await foundationModelsService.queryStateInformation(trimmedQuery)

            // Update with success
            queryState = .success(stateInfo)
        } catch let error as ServiceError {
            // Handle service-specific errors
            errorMessage = error.localizedDescription
            showError = true
            queryState = .error(error.localizedDescription)
        } catch {
            // Handle unexpected errors
            let message = "An unexpected error occurred: \(error.localizedDescription)"
            errorMessage = message
            showError = true
            queryState = .error(message)
        }
    }

    /// Initiates voice recording for speech input
    func startVoiceInput() async {
        // Request permissions if needed
        var hasAuthorization = speechRecognitionService.isAuthorized
        
        if !hasAuthorization {
            hasAuthorization = await speechRecognitionService.requestPermissions()
        }
        
        guard hasAuthorization else {
            errorMessage = "Microphone permission is required for voice input. Please enable it in Settings."
            showError = true
            return
        }

        // Start recording
        do {
            try speechRecognitionService.startRecording()
        } catch {
            errorMessage = "Unable to start voice recording: \(error.localizedDescription)"
            showError = true
        }    }

    /// Stops voice recording and processes the recognized text
    func stopVoiceInput() async {
        speechRecognitionService.stopRecording()

        // Wait a brief moment for final transcription
        try? await Task.sleep(for: .milliseconds(500))

        // Use the recognized text for query
        let recognizedQuery = speechRecognitionService.recognizedText
        if !recognizedQuery.isEmpty {
            searchText = recognizedQuery
            await performQuery(recognizedQuery)
        }
    }

    /// Resets the query state to idle
    func reset() {
        queryState = .idle
        searchText = ""
        errorMessage = nil
        showError = false
        speechRecognitionService.recognizedText = ""
    }

    /// Retry the last query
    func retry() async {
        await performQuery(searchText)
    }
}
