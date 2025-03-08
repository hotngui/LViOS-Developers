import Foundation
import Swift

/// An entity representing an extraterrestrial being in the system.
///
/// The `Alien` struct provides a data model for representing alien entities with basic
/// identification and biographical information.
///
/// ## Overview
/// Use this model to create and manage alien entities in your application. Each alien
/// has a unique identifier and basic information including their name and home planet.
///
/// ```swift
/// let alien = Alien(
///     firstName: "Zorg",
///     lastName: "X",
///     planet: "Mars"
/// )
/// ```
struct Alien: Identifiable {
    /// A unique identifier for the alien.
    let id: UUID
    
    /// The alien's first name.
    let firstName: String
    
    /// The alien's last name.
    let lastName: String
    
    /// The name of the alien's home planet.
    let planet: String
    
    /// An optional URL pointing to the alien's avatar image.
    let avatarURL: URL?
    
    /// Creates a new alien with the specified information.
    /// - Parameters:
    ///   - id: A unique identifier for the alien. Defaults to a new UUID if not provided.
    ///   - firstName: The alien's first name.
    ///   - lastName: The alien's last name.
    ///   - planet: The name of the alien's home planet.
    ///   - avatarURL: An optional URL pointing to the alien's avatar image.
    init(id: UUID = UUID(), firstName: String, lastName: String, planet: String, avatarURL: URL? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.planet = planet
        self.avatarURL = avatarURL
    }
} 