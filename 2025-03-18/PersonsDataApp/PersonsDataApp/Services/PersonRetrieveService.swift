//
// Created by Joey Jarosz on 3/4/25.
// Copyright (c) 2025 Joey Jarosz. All rights reserved.
//

import Foundation

/// A protocol that defines the requirements for retrieving person and alien data.
///
/// Implement this protocol to provide functionality for fetching person and alien data from a data source.
/// The protocol includes a loading state indicator and methods for asynchronous data retrieval.
///
/// ## Topics
/// ### Properties
/// - ``isLoading``
/// ### Fetching Data
/// - ``fetchPersons()``
/// - ``fetchAliens()``
protocol PersonRetrievable {
    /// A Boolean value indicating whether the service is currently loading data.
    var isLoading: Bool { get }

    /// Asynchronously fetches an array of persons from the data source.
    /// - Returns: An array of `Person` objects.
    /// - Throws: An error if the fetch operation fails.
    func fetchPersons() async throws -> [Person]

    /// Asynchronously fetches an array of aliens from the data source.
    /// - Returns: An array of `Alien` objects.
    /// - Throws: An error if the fetch operation fails.
    func fetchAliens() async throws -> [Alien]
}

/// A service class that implements `PersonRetrievable` to fetch person and alien data from a REST API.
///
/// This service manages the retrieval of person and alien data from a local server using URLSession.
/// It handles JSON parsing and provides loading state management.
///
/// ## Example
/// ```swift
/// let service = PersonRetrieveService()
/// do {
///     let persons = try await service.fetchPersons()
///     // Handle the retrieved persons
/// } catch {
///     // Handle any errors
/// }
/// ```
///
/// ## Topics
/// ### Initialization
/// - ``init(urlSession:)``
/// ### Properties
/// - ``isLoading``
/// ### Data Fetching
/// - ``fetchPersons()``
/// - ``fetchAliens()``
class PersonRetrieveService: PersonRetrievable {
    /// The base URL for the API endpoints.
    private let baseURL = "http://127.0.0.1:8080"
    
    /// The URLSession instance used for network requests.
    private let urlSession: URLSession
    
    /// A Boolean value indicating whether the service is currently loading data.
    private(set)var isLoading = false
    
    /// Creates a new instance of PersonRetrieveService.
    /// - Parameter urlSession: The URLSession to use for network requests. Defaults to `.shared`.
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    /// Asynchronously fetches an array of persons from the server.
    /// - Returns: An array of `Person` objects decoded from the server response.
    /// - Throws: An error if the network request fails or if the response cannot be decoded.
    func fetchPersons() async throws -> [Person] {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/persons")!
        let (data, _) = try await urlSession.data(from: url)

        return try JSONDecoder().decode([Person].self, from: data)
    }
    
    /// Asynchronously fetches an array of aliens from the server.
    /// - Returns: An array of `Alien` objects parsed from the server response.
    /// - Throws: An error if the network request fails, if the JSON is invalid, or if required fields are missing.
    func fetchAliens() async throws -> [Alien] {
        isLoading = true
        defer { isLoading = false }
        
        let url = URL(string: "\(baseURL)/aliens")!
        let (data, _) = try await urlSession.data(from: url)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw NSError(domain: "AlienParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
        }
        
        return try json.map { dict in
            guard let idString = dict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let firstName = dict["firstName"] as? String,
                  let lastName = dict["lastName"] as? String,
                  let planet = dict["planet"] as? String else {
                throw NSError(domain: "AlienParsingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required fields"])
            }
            
            let avatarURLString = dict["avatarURL"] as? String
            let avatarURL = avatarURLString.flatMap { URL(string: $0) }
            
            return Alien(
                id: id,
                firstName: firstName,
                lastName: lastName,
                planet: planet,
                avatarURL: avatarURL
            )
        }
    }
}

