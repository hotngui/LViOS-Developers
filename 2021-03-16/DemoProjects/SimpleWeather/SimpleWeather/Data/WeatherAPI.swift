//
// Created by Joey Jarosz on 3/6/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import Combine

// MARK: - Data Representation

struct Location: Decodable {
    var name: String
    var region: String
    var localtime_epoch: Int
}

struct Current: Decodable {
    var observation_time: String
    var temperature: Int
    var weather_icons: [String]
    var weather_descriptions: [String]
}

struct Weather: Decodable {
    var location: Location
    var current: Current
}

// MARK: - Data Retrieval

/// We use a simple API to retrieve some weather data for demo purposes. This particular API will not let us use HTTPS when using their free accounts, so
/// you need to make sure NSAppTransportSecurity is set to to allow arbitrary loads in the _Info.plist_.
///
class WeatherAPI {
    private var subscriptions: [AnyCancellable] = []

    /// Retrieve
    ///
    /// - Parameters:
    ///   - location: The latitude/longitude of interest
    ///   - results: The closure to be called when we have a result/error
    ///
    func current(for location: String, results: @escaping (Result<Weather, Error>) -> Void) {
        guard var urlComponents = URLComponents(string: "http://api.weatherstack.com/current") else {
            return
        }

        let queryItems = [
            URLQueryItem(name: "query", value: location),
            URLQueryItem(name: "access_key", value: "252d1c9992db40325c574ee55ca25288"),
            URLQueryItem(name: "units", value: "m")
        ]

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            return
        }

        // Use the new Combine based extensions to call the RESTful API and get the current weather...
        URLSession.shared
            .dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: Weather.self, decoder: JSONDecoder())
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    results(.failure(error))
                }
            },
            receiveValue: { object in
                results(.success(object))
            })
            .store(in: &subscriptions)
    }
}
