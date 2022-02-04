//
// Created by Joey Jarosz on 2/2/22.
// Copyright © 2022 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

///
struct User: Hashable {
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

extension User {
    init?(json: [String: Any]) {
        guard let birthday = json["birthday"] as? TimeInterval,
              let lastName = json["lastName"] as? String,
              let firstName = json["firstName"] as? String,
              let streetAddress = json["streetAddress"] as? String,
              let city = json["city"] as? String,
              let zipCode = json["zipCode"] as? Int,
              let avatar = json["avatar"] as? String else {
            return nil
        }

        self.birthday = Date(timeIntervalSince1970: birthday)
        self.lastName = lastName
        self.firstName = firstName
        self.streetAddress = streetAddress
        self.city = city
        self.zipCode = zipCode

        if let avatar = URL(string: avatar) {
            self.avatar = avatar
        } else {
            return nil
        }

        //
        guard let classificationJSON = json["classification"] as? [String: Any] else {
            return nil
        }

        if classificationJSON["geek"] != nil {
            self.classification = .geek
        } else if classificationJSON["customer"] != nil {
            self.classification = .customer
        } else if classificationJSON["management"] != nil {
            self.classification = .management
        } else {
            guard let nerdJSON = classificationJSON["nerd"] as? [String: Any], let level = nerdJSON["level"] as? Int else {
                return nil
            }
            self.classification = .nerd(level: level)
        }
    }

    func toJSON() -> [String: Any] {
        var result = [String: Any]()

        result["birthday"] = self.birthday.timeIntervalSinceReferenceDate
        result["lastName"] = self.lastName
        result["firstName"] = self.firstName
        result["streetAddress"] = self.streetAddress
        result["city"] = self.city
        result["zipCode"] = self.zipCode
        result["avatar"] = self.avatar.absoluteString

        var classificationJSON = [String: Any]()
        var levelJSON = [String: Any]()

        switch classification {
        case .nerd(let level):
            levelJSON["nerd"] = ["level": level]
        case .geek:
            levelJSON["geek"] = [:]
        case .customer:
            levelJSON["customer"] = [:]
        case .management:
            levelJSON["management"] = [:]
        }

        classificationJSON = levelJSON
        result["classification"] = classificationJSON

        return result
    }
}

/// The world's simpliest, dumbest data reader for testing purpses. Reads a local JSON file and creates User objects.
///
func readData() -> [User]? {
    if let data = LocalJSONReader.read(from: "Users") {
        if let objects = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [[String: Any]] {
            var users = [User]()

            for object in objects {
                if let user = User(json: object) {
                    users.append(user)
                }
            }

           return users
        }
    }

    return nil
}
