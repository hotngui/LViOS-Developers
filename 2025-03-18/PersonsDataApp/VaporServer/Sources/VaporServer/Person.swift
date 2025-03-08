import Foundation
import Vapor

struct Person: Codable, Content {
    let id: UUID
    let firstName: String
    let lastName: String
    let address: String
    let avatarURL: URL?
    
    init(id: UUID = UUID(), firstName: String, lastName: String, address: String, avatarURL: URL?) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.avatarURL = avatarURL
    }
}