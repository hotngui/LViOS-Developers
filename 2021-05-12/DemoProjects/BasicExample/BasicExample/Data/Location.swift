//
// Created by Joey Jarosz on 5/10/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

struct LocationResults: Decodable {
    let locations: [Location]

    //
    static func loadSampleData() -> [Location] {
        guard let path = Bundle.main.path(forResource: "Locations", ofType: "json") else {
            preconditionFailure()
        }

        guard let data = FileManager.default.contents(atPath: path) else {
            preconditionFailure()
        }

        let decoder = JSONDecoder()

        do {
            let results = try decoder.decode(LocationResults.self, from: data)
            return results.locations
        }
        catch (let error) {
            preconditionFailure(error.localizedDescription)
        }
    }
}

struct Location: Decodable, Identifiable, Hashable {
    enum BusinessType: String, Decodable {
        case casino
        case hospital
    }

    let id: Int
    let name: String
    let address: String
    let type: BusinessType
    let latitude: Double
    let longitude: Double

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

