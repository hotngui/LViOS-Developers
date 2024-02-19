//
// Created by Joey Jarosz on 2/15/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

@main
struct WeatherKitExampleApp: App {
    @State var locationManager = LocationManager()
    @State var weatherManager = WeatherManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationManager)
                .environment(weatherManager)
        }
    }
}
