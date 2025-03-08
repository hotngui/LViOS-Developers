import Vapor

// Configure and start the server
let app = try Application(.detect())
defer { app.shutdown() }

// Sample data
let samplePersons: [Person] = [
    Person(
        firstName: "John",
        lastName: "Doe",
        address: "123 Main St, New York, NY",
        avatarURL: URL(string: "https://picsum.photos/id/237/200")!
    ),
    Person(
        firstName: "Jane",
        lastName: "Smith",
        address: "456 Park Ave, Los Angeles, CA",
        avatarURL: URL(string: "https://picsum.photos/id/870/200")!
    ),
    Person(
        firstName: "Bob",
        lastName: "Johnson",
        address: "789 Oak Rd, Chicago, IL",
        avatarURL: URL(string: "https://picsum.photos/id/1084/200")!
    )
]

// Sample alien data
let sampleAliens: [Alien] = [
    Alien(
        firstName: "Zorg",
        lastName: "X-742",
        planet: "Mars",
        avatarURL: URL(string: "https://picsum.photos/id/1025/200")!
    ),
    Alien(
        firstName: "Klix",
        lastName: "Quantum",
        planet: "Venus",
        avatarURL: URL(string: "https://picsum.photos/id/1027/200")!
    ),
    Alien(
        firstName: "Nebula",
        lastName: "Star",
        planet: "Jupiter",
        avatarURL: URL(string: "https://picsum.photos/id/1029/200")!
    ),
    Alien(
        firstName: "Cosmo",
        lastName: "Nova",
        planet: "Saturn",
        avatarURL: URL(string: "https://picsum.photos/id/1031/200")!
    ),
    Alien(
        firstName: "Luna",
        lastName: "Eclipse",
        planet: "Neptune",
        avatarURL: URL(string: "https://picsum.photos/id/1033/200")!
    )
]

// Configure routes
app.get("persons") { req async throws -> [Person] in
    return samplePersons
}

app.get("aliens") { req async throws -> [Alien] in
    return sampleAliens
}

// Start the server
try app.run() 