//
// Created by Joey Jarosz on 2/19/23.
// Copyright © 2023 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

class DataModel: ObservableObject {
    private enum Constants {
        static let valuesKey = "ValuesKey"
    }
    
    @Published var data: [Double] = []

    init() {
        if let rawValues = UserDefaults.standard.array(forKey: Constants.valuesKey) {
            data = rawValues.compactMap({ value in
                return (value as? Double)
            })
        }
    }
    
    func add(value: Double) {
        data.insert(value, at: 0)
        UserDefaults.standard.set(data, forKey: Constants.valuesKey)
    }
    
    func newestValue() -> Double? {
        data.first
    }
}
