//
// FoundationModelsService.swift
// Created by Joey Jarosz on 12/14/25.
// Copyright (c) 2025 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import FoundationModels

/// Service wrapper for Apple's FoundationModels framework
/// Implements guardrails to ensure only US state queries are processed
@MainActor
final class FoundationModelsService {

    // MARK: - Properties

    private let model: SystemLanguageModel
    private var session: LanguageModelSession?

    // MARK: - Initialization

    init() {
        // Get the default system language model
        self.model = SystemLanguageModel.default
    }

    // MARK: - Public Methods

    /// Query state information using the Foundation Models framework
    /// - Parameter query: User's natural language query about a US state
    /// - Returns: StateInformation if the query is valid, throws error if guardrails reject it
    /// - Throws: ServiceError if the query is not about a US state or if generation fails
    func queryStateInformation(_ query: String) async throws -> StateInformation {
        // First, validate that the query is about a US state using guardrails
        let isValidStateQuery = try await validateStateQuery(query)

        guard isValidStateQuery else {
            throw ServiceError.invalidQuery("I can only provide information about US states. Try asking about a state like 'California' or 'New York'.")
        }

        let instructions = """
        You are a helpful assistant that provides accurate information about US states.
        Always respond with complete and accurate information about the requested state.
        Include the state name, capital city, state bird, state plant/flower, and approximate geographic coordinates for the state's center.
        If state bird or plant information is not available, use null for those fields.
        Only respond to queries about the 50 US states.
        """

        let session = LanguageModelSession(model: model, instructions: instructions)

// TODO: You must assign the `instructions` at initialize time of the session
//        // Create a new session for this query
//        let session = LanguageModelSession(model: model)
//
//        // Set instructions to guide the model's behavior
//        session.instructions = """
//        You are a helpful assistant that provides accurate information about US states.
//        Always respond with complete and accurate information about the requested state.
//        Include the state name, capital city, state bird, state plant/flower, and approximate geographic coordinates for the state's center.
//        If state bird or plant information is not available, use null for those fields.
//        Only respond to queries about the 50 US states.
//        """

        // Prepare the prompt with the user's query
        let prompt = """
        Please provide comprehensive information about the following US state query: \(query)

        Include:
        - State name (official name)
        - Capital city
        - State bird (official state bird)
        - State plant or flower (official state flower or plant)
        - Geographic center coordinates (latitude and longitude)
        """

        do {
            // Use guided generation to get a typed Swift struct back
            let response = try await session.respond(to: prompt, generating: StateInformation.self)

// TODO: No such method named `generate` exists
//            let response = try await session.generate(prompt, of: StateInformation.self)

            return response.content
        } catch {
            // Handle generation errors
            throw ServiceError.generationFailed("Unable to generate state information. Please try again. Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Validates that the query is about a US state
    /// This implements the guardrail logic to reject non-state queries
    private func validateStateQuery(_ query: String) async throws -> Bool {
        let instructions = """
        You are a query validator that determines if a question is asking about one of the 50 US states.
        You must respond with ONLY "true" or "false".
        - Return "true" if the query is asking about any of the 50 US states
        - Return "false" if the query is about anything else (countries, cities that aren't states, general questions, etc.)
        """

        // Create a temporary session for validation
        let validationSession = LanguageModelSession(model: model, instructions: instructions)

// TODO: You must assign the `instructions` at initialize time of the session
//        // Create a temporary session for validation
//        let validationSession = LanguageModelSession(model: model)
//
//        validationSession.instructions = """
//        You are a query validator that determines if a question is asking about one of the 50 US states.
//        You must respond with ONLY "true" or "false".
//        - Return "true" if the query is asking about any of the 50 US states
//        - Return "false" if the query is about anything else (countries, cities that aren't states, general questions, etc.)
//        """

        let validationPrompt = """
        Is this query asking about one of the 50 US states? Answer only "true" or "false".
        Query: \(query)
        """

        do {
            // Get validation response
            let response = try await validationSession.respond(to: validationPrompt)
            let cleanedResponse = response.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            return cleanedResponse.contains("true")
        } catch {
            // If validation fails, err on the side of caution and reject the query
            return false
        }
    }
}

// MARK: - Service Errors

/// Custom errors for the FoundationModels service
enum ServiceError: LocalizedError {
    case invalidQuery(String)
    case generationFailed(String)
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidQuery(let message):
            return message
        case .generationFailed(let message):
            return message
        case .modelUnavailable:
            return "The language model is currently unavailable. Please ensure you're running on a compatible device with iOS 26+."
        }
    }
}
