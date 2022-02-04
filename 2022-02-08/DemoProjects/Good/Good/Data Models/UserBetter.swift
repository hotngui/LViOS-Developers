//
// Created by Joey Jarosz on 2/2/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

///
struct User: Codable, Hashable {
    enum Classification: Hashable {
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

///
extension User.Classification: Codable {
    private enum CodingKeys: String, CodingKey {
        case nerd
        case geek
        case customer
        case management
    }

    enum classificationKeys: CodingKey {
      case geek, customer, management
    }


    enum CodingError: Error {
        case decoding(String)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        if let codes = try? values.decode([String: Int].self, forKey: .nerd), let level = codes["level"] {
            self = .nerd(level: level)
            return
        }

        if let _ = try? values.decode(Dictionary<String, String>.self, forKey: .geek) {
            self = .geek
            return
        }

        if let _ = try? values.decode(Dictionary<String, String>.self, forKey: .customer) {
            self = .customer
            return
        }

        if let _ = try? values.decode(Dictionary<String, String>.self, forKey: .management) {
            self = .management
            return
        }

        throw CodingError.decoding("Decoding Error: \(dump(values))")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .nerd(let level):
            try container.encode(["level": level], forKey: .nerd)
        case .geek:
            try container.encode(Dictionary<String, String>(), forKey: .geek)
        case .customer:
            try container.encode(Dictionary<String, String>(), forKey: .customer)
        case .management:
            try container.encode(Dictionary<String, String>(), forKey: .management)
        }
    }
}

/// The world's simpliest, dumbest data reader for testing purpses. Reads a local JSON file and creates User objects.
///
func readData() -> [User]? {
    if let data = LocalJSONReader.read(from: "Users") {
        return try? JSONDecoder().decode([User].self, from: data)
    }

    return nil
}
