//
// Created by Joey Jarosz on 3/6/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation

///
class WeatherByLocation: NSObject {
    private let weatherApi = WeatherAPI()
    private var handler: ((Result<Weather, Error>) -> Void)?

    enum WeatherError: Error {
        case noLocation
    }

    func getWeather(location: String?, handler: @escaping (Result<Weather, Error>) -> Void) {
        self.handler = handler
        getWeather(for: location)
    }

    ///
    private func getWeather(for location: String?) {
        guard let location = location else {
            handler?(.failure(WeatherError.noLocation))
            return
        }

        weatherApi.current(for: location) { [weak self] result in
            self?.handler?(result)
        }
    }
}
