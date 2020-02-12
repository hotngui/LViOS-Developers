//
//  Created by Joey Jarosz on 2/11/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

/// A simple class that represents the JSON data in our sample data file. Basically its an array of restaurants.
///
class RestaurantData: Decodable {
    var restaurants: [Restaurant]
}

/// The definition of a 'Resstaurant' object as defined by the JSON file. Its extremely simple for sample purposes but you can see how it works. The key to making this data usable
/// by SwiftUI is that the class adopts the `Identifiable` protocol which requires a unique identifier vai the `id` property. The rest of the data is specific to our application.
///
class Restaurant: Decodable, Identifiable {
    var id: Int
    var name: String
    var address: String

    init(id: Int, name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}

