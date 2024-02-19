//
// Created by Joey Jarosz on 2/15/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherManager.self) private var weatherManager
    
    var body: some View {
        if locationManager.location == nil {
            NoContentView()
        } else {
            if let forecast = weatherManager.forecast {
                WeatherView(currentWeather: forecast.0, forecast: forecast.1)
            } else {
                LocationView()
            }
        }
    }
}

#Preview {
    ContentView()
}
