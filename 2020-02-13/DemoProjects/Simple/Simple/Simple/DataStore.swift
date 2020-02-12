//
//  Created by Joey Jarosz on 2/11/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import Foundation


/// This class reads a bunch of JSON data from a file shipped with the app. For a real app, this JSON data would more likely come down from the cloud for
/// a network request. Except for where the data comes from the rest of the code here would be exactly the same. 
///
class DataStore {
    static func getRestaurants() -> [Restaurant] {
        guard let filepath = Bundle(for: self).path(forResource: "SampleData", ofType: "json"), let data = FileManager.default.contents(atPath: filepath) else {
            print("Could not find sample data file.")
            return []
        }

        do {
            let decoder = JSONDecoder()
            let restaurants = try decoder.decode(RestaurantData.self, from: data)

            let sortedValues = restaurants.restaurants.sorted { (r1, r2) -> Bool in
                return r1.name < r2.name
            }

            return sortedValues
        }
        catch {
            print("Error when decoding: \(error)")
        }

        return []
    }
}
