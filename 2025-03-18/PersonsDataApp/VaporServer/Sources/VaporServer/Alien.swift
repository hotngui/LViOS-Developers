import Foundation
import Vapor

struct Alien: Codable, Content {
    let id: UUID
    let firstName: String
    let lastName: String
    let planet: String
    let avatarURL: URL?
    
    init(id: UUID = UUID(), firstName: String, lastName: String, planet: String, avatarURL: URL?) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.planet = planet
        self.avatarURL = avatarURL
    }
} 