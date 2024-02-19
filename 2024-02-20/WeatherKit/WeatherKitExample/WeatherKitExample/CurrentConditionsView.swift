//
// Created by Joey Jarosz on 2/18/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import WeatherKit

struct CurrentConditionsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(WeatherManager.self) private var weatherManager

    let symbolName: String
    let temperature: Measurement<UnitTemperature>
    let feelsLike: Measurement<UnitTemperature>
    
    var body: some View {
        HStack {
            SymbolView(symbolName: symbolName)
                .frame(maxWidth: .infinity)

            VStack(spacing: 0) {
                Text(temperature.format())
                    .font(.largeTitle)
                    .bold()
                    .scaledToFit()
                
                Text("Feels like: \(feelsLike.format())")
                    .italic()
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .bottomTrailing) {
            if let attribution = weatherManager.attribution {
                VStack {
                    AsyncImage(url: attribution.logo) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {}
                        .frame(maxWidth: 75)
                    
                    Link("Other data sources", destination: attribution.link)
                        .font(.caption)
                }
                .padding(.trailing, 10)
            }
        }
        .task {
            weatherManager.attribution(for: colorScheme)
        }
    }
}

// MARK: - Private Views

private struct SymbolView: View {
    let symbolName: String
    
    var body: some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.palette)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.primary, Color.accentColor, Color.orange)
            .padding(20)
    }
}

// MARK: - Previews

#Preview("CurrentConditionsView") {
    @State var weatherManager = WeatherManager()

    return CurrentConditionsView(symbolName: "cloud.drizzle",
                                 temperature: Measurement(value: 39.0, unit: UnitTemperature.celsius),
                                 feelsLike: Measurement(value: 32.0, unit: UnitTemperature.celsius))
        .environment(weatherManager)
}

#Preview("SymbolView") {
    SymbolView(symbolName: "cloud.drizzle")
}
