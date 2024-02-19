//
// Created by Joey Jarosz on 2/17/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import CoreLocation
import WeatherKit
import OSLog

///
///
@Observable
class WeatherManager {
    private let logger = Logger(subsystem: "com.hotngui.WeatherKitExample", category: "weatherForecast")
    private let weatherService = WeatherService.shared

    var forecast: (CurrentWeather, Forecast<DayWeather>)?
    var attribution: (logo: URL, link: URL)?
    
    // MARK: - Public Methods
    
    func attribution(for colorScheme: ColorScheme) {
        Task {
            do {
                let attr = try await weatherService.attribution
                
                let logo = (colorScheme == .dark ? attr.combinedMarkDarkURL : attr.combinedMarkLightURL)
                let link = attr.legalPageURL

                attribution = (logo: logo, link: link)
            }
            catch (let error) {
                logger.error("Failed to retreive da'weather: \(error)")
                attribution = nil
            }
        }
    }
    
    func getForecast(for location: CLLocation?) {
        guard let location else {
            return
        }
        
        Task {
            do {
                let (current, daily) = try await weatherService.weather(for: location, including: .current, .daily)
                forecast = (current, daily)
            }
            catch (let error) {
                forecast = nil
                logger.error("Failed to retreive da'weather: \(error)")
            }
        }
    }
}
