//
// Created by Joey Jarosz on 2/18/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

extension Measurement<UnitTemperature> {
    func format() -> String {
        self.formatted(
            .measurement(width: .abbreviated,
                         usage: .general,
                         numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}
