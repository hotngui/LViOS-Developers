//
// Created by Joey Jarosz on 3/7/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

class Defaults {
    private let defaults = UserDefaults.standard

    func storeLocation(_ location: String) {
        defaults.setValue(location, forKey: "Location")
    }

    func getLocation() -> String? {
        return defaults.string(forKey: "Location")
    }
}
