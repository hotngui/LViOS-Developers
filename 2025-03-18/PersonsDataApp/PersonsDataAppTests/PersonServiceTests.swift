//
// Created by Joey Jarosz on 3/6/25.
// Copyright (c) 2025 Joey Jarosz. All rights reserved.
//

import Foundation
import Testing
@testable import PersonsDataApp

struct PersonServiceTests {
    @Test func fetchesPersonsSuccessfully() async throws {
        // Given
        let service = MockPersonService()
        
        // When
        let persons = try await service.fetchPersons()
        
        // Then
        #expect(persons.count == 2)
        #expect(persons[0].id.uuidString == "123E4567-E89B-12D3-A456-426614174000")
        #expect(persons[0].firstName == "John")
        #expect(persons[0].lastName == "Doe")
        #expect(persons[0].avatarURL == URL(string: "https://example.com/avatar.jpg"))
        #expect(persons[1].avatarURL == nil)
    }
    
    @Test func handlesError() async throws {
        // Given
        let service = MockPersonService()
        service.shouldError = true
        
        // Then
        await #expect(throws: URLError.self) {
            _ = try await service.fetchPersons()
        }
    }
    
    @Test func managesLoadingState() async throws {
        // Given
        let service = MockPersonService()
        service.delayInSeconds = 0.1
        
        // Then initial state
        #expect(!service.isLoading)
        
        // When starting the request
        let task = Task {
            try await service.fetchPersons()
        }
        
        // Give the task a moment to start
        try await Task.sleep(for: .milliseconds(50))
        
        // Then loading should be true during the request
        #expect(service.isLoading)
        
        // When the request completes
        _ = try await task.value
        
        // Then loading should be false after completion
        #expect(!service.isLoading)
    }
    
    @Test func fetchesAliensSuccessfully() async throws {
        // Given
        let service = MockPersonService()
        
        // When
        let aliens = try await service.fetchAliens()
        
        // Then
        #expect(aliens.count == 3)
        #expect(aliens[0].id.uuidString == "ABCDEF12-3456-7890-ABCD-EF1234567890")
        #expect(aliens[0].firstName == "Zorblax")
        #expect(aliens[0].lastName == "Quantum")
        #expect(aliens[0].planet == "Nexus Prime")
        #expect(aliens[0].avatarURL == URL(string: "https://example.com/alien1.jpg"))
        #expect(aliens[2].avatarURL == nil)
    }
    
    @Test func handlesErrorForAliens() async throws {
        // Given
        let service = MockPersonService()
        service.shouldError = true
        
        // Then
        await #expect(throws: URLError.self) {
            _ = try await service.fetchAliens()
        }
    }
    
    @Test func managesLoadingStateForAliens() async throws {
        // Given
        let service = MockPersonService()
        service.delayInSeconds = 0.1
        
        // Then initial state
        #expect(!service.isLoading)
        
        // When starting the request
        let task = Task {
            try await service.fetchAliens()
        }
        
        // Give the task a moment to start
        try await Task.sleep(for: .milliseconds(50))
        
        // Then loading should be true during the request
        #expect(service.isLoading)
        
        // When the request completes
        _ = try await task.value
        
        // Then loading should be false after completion
        #expect(!service.isLoading)
    }
} 

// MARK: - Mock Service

class MockPersonService: PersonRetrievable {
    private(set) var isLoading = false
    var shouldError = false
    var delayInSeconds: TimeInterval = 0
    
    let samplePersons = [
        Person(
            id: UUID(uuidString: "123e4567-e89b-12d3-a456-426614174000")!,
            firstName: "John",
            lastName: "Doe",
            address: "123 Main St",
            avatarURL: URL(string: "https://example.com/avatar.jpg")
        ),
        Person(
            id: UUID(uuidString: "987fcdeb-89ab-12cd-3456-426614174000")!,
            firstName: "Jane",
            lastName: "Smith",
            address: "456 Oak Ave",
            avatarURL: nil
        )
    ]
    
    let sampleAliens = [
        Alien(
            id: UUID(uuidString: "abcdef12-3456-7890-abcd-ef1234567890")!,
            firstName: "Zorblax",
            lastName: "Quantum",
            planet: "Nexus Prime",
            avatarURL: URL(string: "https://example.com/alien1.jpg")
        ),
        Alien(
            id: UUID(uuidString: "12345678-90ab-cdef-1234-567890abcdef")!,
            firstName: "Nebula",
            lastName: "Starweaver",
            planet: "Celestial Haven",
            avatarURL: URL(string: "https://example.com/alien2.jpg")
        ),
        Alien(
            id: UUID(uuidString: "98765432-10fe-dcba-9876-543210fedcba")!,
            firstName: "Quasar",
            lastName: "Voidwalker",
            planet: "Dark Matter Realm",
            avatarURL: nil
        )
    ]
    
    func fetchPersons() async throws -> [Person] {
        isLoading = true
        defer { isLoading = false }
        
        if delayInSeconds > 0 {
            try await Task.sleep(for: .seconds(delayInSeconds))
        }
        
        if shouldError {
            throw URLError(.notConnectedToInternet)
        }
        
        return samplePersons
    }
    
    func fetchAliens() async throws -> [Alien] {
        isLoading = true
        defer { isLoading = false }
        
        if delayInSeconds > 0 {
            try await Task.sleep(for: .seconds(delayInSeconds))
        }
        
        if shouldError {
            throw URLError(.notConnectedToInternet)
        }
        
        return sampleAliens
    }
} 
