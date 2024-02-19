//
// Created by Joey Jarosz on 2/18/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import CoreLocation
import CoreLocationUI

struct LocationView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherManager.self) private var weatherManager
    
    var body: some View {
        VStack {
            HStack {
                Text(locationManager.cityState ?? "")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .font(.title)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                LocationButton {
                    locationManager.requestLocation { location in
                        weatherManager.getForecast(for: location)
                    }
                }
                .foregroundStyle(.white)
                .labelStyle(.iconOnly)
                .clipShape(Capsule())
            }
            .padding()
            
            if weatherManager.forecast == nil {
                Spacer()
            }
        }
    }
}

#Preview {
    @State var locationManager = LocationManager()
    @State var weatherManager = WeatherManager()

    return LocationView()
        .environment(locationManager)
        .environment(weatherManager)
}
