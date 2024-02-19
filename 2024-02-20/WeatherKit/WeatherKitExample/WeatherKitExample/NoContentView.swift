//
// Created by Joey Jarosz on 2/17/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct NoContentView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherManager.self) private var weatherManager

    var body: some View {
        ContentUnavailableView(label: {
            Label(
                title: {
                    Text("Where you be?")
                },
                icon: {
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                }
            )
            .labelStyle(CustomLabelStyle())
            .padding(20)
        }, description: {
            Text("We need to know your current location in order to provide you with forecast information.")
        }, actions: {
            LocationButton(.currentLocation) {
                locationManager.requestLocation { location in
                    weatherManager.getForecast(for: location)
                }
            }
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .labelStyle(.titleAndIcon)
        })
    }
}


#Preview {
    @State var locationManager = LocationManager()
    @State var weatherManager = WeatherManager()

    return NoContentView()
        .environment(locationManager)
        .environment(weatherManager)
}
