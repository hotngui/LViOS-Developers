//
// Created by Joey Jarosz on 10/7/23.
// 
//

import Foundation
import SwiftData

@Model
final class Item {
    var lastName: String
    var firstName: String
    var street: String
    var city: String
    var state: String
    var zip: Int64
    
    init(lastName: String, firstName: String, street: String, city: String, state: String, zip: Int64) {
        self.lastName = lastName
        self.firstName = firstName
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
    }
}
