//
// Created by Joey Jarosz on 3/6/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

/// Representts our weather data in a form more easily consumed by our user interface code.
///
struct WeatherViewModel {
    var city: String
    var state: String
    var temperature: String
    var description: String
    var lastCheckedTime: Date
    var iconUrl: URL?

    init(with weather: Weather) {
        self.city = weather.location.name
        self.state = weather.location.region
        self.lastCheckedTime = Date(timeIntervalSince1970: Double(weather.location.localtime_epoch))
        self.description = weather.current.weather_descriptions.first ?? ""

        // The temperature received in celsius but being American I want to show it always as Faranheight, we
        // also only want to show whole numbers...
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0

        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter = numberFormatter

        var measurement = Measurement(value: Double(weather.current.temperature), unit: UnitTemperature.celsius)
        measurement = measurement.converted(to: .fahrenheit)

        self.temperature = measurementFormatter.string(from: measurement)

        // Grab the first image and we'll use it in our displays...
        if let urlStr = weather.current.weather_icons.first {
            self.iconUrl = URL(string: urlStr)
        }
    }
}
