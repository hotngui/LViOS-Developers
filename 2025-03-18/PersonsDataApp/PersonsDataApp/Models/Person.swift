//
// Created by Joey Jarosz on 3/3/25.
// Copyright (c) 2025 Joey Jarosz. All rights reserved.
//

import Foundation
import Swift

/// A model representing a person in the system.
///
/// The `Person` struct provides a data model for representing individuals with basic
/// identification and contact information. It supports JSON decoding with strict URL validation.
///
/// ## Overview
/// Use this model to create and manage person entities in your application. Each person
/// has a unique identifier and basic information including their name and address.
///
/// ```swift
/// let person = Person(
///     firstName: "John",
///     lastName: "Doe",
///     address: "123 Main St"
/// )
/// ```
///
/// ## Topics
/// ### Creating a Person
/// - ``init(id:firstName:lastName:address:avatarURL:)``
/// - ``init(from:)``
struct Person: Decodable, Identifiable {
    /// A unique identifier for the person.
    let id: UUID
    
    /// The person's first name.
    let firstName: String
    
    /// The person's last name.
    let lastName: String
    
    /// The person's address.
    let address: String
    
    /// An optional URL pointing to the person's avatar image.
    let avatarURL: URL?
    
    /// Creates a new person with the specified information.
    /// - Parameters:
    ///   - id: A unique identifier for the person. Defaults to a new UUID if not provided.
    ///   - firstName: The person's first name.
    ///   - lastName: The person's last name.
    ///   - address: The person's address.
    ///   - avatarURL: An optional URL pointing to the person's avatar image.
    init(id: UUID = UUID(), firstName: String, lastName: String, address: String, avatarURL: URL? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.avatarURL = avatarURL
    }
    
    /// The coding keys used for encoding and decoding the person model.
    enum CodingKeys: String, CodingKey {
        case id, firstName, lastName, address, avatarURL
    }
    
    /// Creates a new person instance by decoding from the given decoder.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: An error if data is missing or malformed, including invalid URL formats.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        address = try container.decode(String.self, forKey: .address)
        
        // Strict URL decoding with validation
        if let urlString = try container.decodeIfPresent(String.self, forKey: .avatarURL) {
            guard let components = URLComponents(string: urlString),
                  let scheme = components.scheme,
                  ["http", "https"].contains(scheme.lowercased()),
                  let host = components.host,
                  !host.isEmpty
            else {
                throw DecodingError.dataCorruptedError(
                    forKey: .avatarURL,
                    in: container,
                    debugDescription: "Invalid URL format: \(urlString). URL must have a valid scheme (http/https) and host."
                )
            }
            
            guard let url = components.url else {
                throw DecodingError.dataCorruptedError(
                    forKey: .avatarURL,
                    in: container,
                    debugDescription: "Could not create URL from components: \(urlString)"
                )
            }
            avatarURL = url
        } else {
            avatarURL = nil
        }
    }
}
