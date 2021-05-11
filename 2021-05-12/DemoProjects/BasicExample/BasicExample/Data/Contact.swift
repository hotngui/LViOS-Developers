//
// Created by Joey Jarosz on 5/10/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

struct Results: Decodable {
    let contacts: [Contact]

    //
    static func loadSampleData() -> [Contact] {
        guard let path = Bundle.main.path(forResource: "Contacts", ofType: "json") else {
            preconditionFailure()
        }

        guard let data = FileManager.default.contents(atPath: path) else {
            preconditionFailure()
        }

        let decoder = JSONDecoder()

        do {
            let results = try decoder.decode(Results.self, from: data)
            return results.contacts
        }
        catch (let error) {
            preconditionFailure(error.localizedDescription)
        }
    }
}

struct Contact: Decodable, Identifiable, Hashable {
    let id: Int
    let firstName: String
    let lastName: String
    let streetAddress: String
    let city: String
    let stateShort: String
    let stateLong: String
    let zipCode: String
    let telephone: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

