//
// Created by Joey Jarosz on 2/17/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import WeatherKit

struct WeatherView: View {
    @Environment(WeatherManager.self) private var weatherManager

    let currentWeather: CurrentWeather
    let forecast: Forecast<DayWeather>
    
    var body: some View {
        VStack {
            LocationView()

            CurrentConditionsView(symbolName: currentWeather.symbolName,
                                  temperature: currentWeather.temperature,
                                  feelsLike: currentWeather.apparentTemperature)

            Divider()

            ForecastView(forecast: forecast)
        }
    }
}
