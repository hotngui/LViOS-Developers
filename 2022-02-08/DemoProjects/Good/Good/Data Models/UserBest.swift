//
// Created by Joey Jarosz on 2/2/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

///
struct User: Codable, Hashable {
    enum Classification: Codable, Hashable {
        case nerd(level: Int)
        case geek
        case customer
        case management
    }

    let birthday: Date
    let lastName: String
    let firstName: String
    let streetAddress: String
    let city: String
    let zipCode: Int
    let avatar: URL
    let classification: Classification
}

/// The world's simpliest, dumbest data reader for testing purpses. Reads a local JSON file and creates User objects.
///
func readData() -> [User]? {
    if let data = LocalJSONReader.read(from: "Users") {
        return try? JSONDecoder().decode([User].self, from: data)
    }
    
    return nil
}
