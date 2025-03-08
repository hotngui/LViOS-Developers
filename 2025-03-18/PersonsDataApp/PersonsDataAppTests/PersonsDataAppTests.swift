//
// Created by Joey Jarosz on 3/3/25.
// Copyright (c) 2025 Joey Jarosz. All rights reserved.
//

import Foundation
import Testing
@testable import PersonsDataApp

struct PersonTests {
    @Test func decodesValidPersonData() throws {
        // Given
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "firstName": "John",
            "lastName": "Doe",
            "address": "123 Main St, City, Country",
            "avatarURL": "https://example.com/avatar.jpg"
        }
        """.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: json)
        
        // Then
        #expect(person.id.uuidString == "123E4567-E89B-12D3-A456-426614174000")
        #expect(person.firstName == "John")
        #expect(person.lastName == "Doe")
        #expect(person.address == "123 Main St, City, Country")
        #expect(person.avatarURL == URL(string: "https://example.com/avatar.jpg"))
    }
    
    @Test func failsToDecodeInvalidURL() throws {
        // Given
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "firstName": "John"  ,
            "lastName": "Doe",
            "address": "123 Main St, City, Country",
            "avatarURL": "not-a-valid-url"
        }
        """.data(using: .utf8)!
        
        // Then
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Person.self, from: json)
        }
    }
    
    @Test func decodesPersonWithNullAvatarURL() throws {
        // Given
        let json = """
        {
            "id": "123e4567-e89b-12d3-a456-426614174000",
            "firstName": "John",
            "lastName": "Doe",
            "address": "123 Main St, City, Country",
            "avatarURL": null
        }
        """.data(using: .utf8)!
        
        // When
        let person = try JSONDecoder().decode(Person.self, from: json)
        
        // Then
        #expect(person.id.uuidString == "123E4567-E89B-12D3-A456-426614174000")
        #expect(person.firstName == "John")
        #expect(person.lastName == "Doe")
        #expect(person.address == "123 Main St, City, Country")
        #expect(person.avatarURL == nil)
    }
}

