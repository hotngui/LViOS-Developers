//
// Created by Joey Jarosz on 2/18/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI
import WeatherKit


struct ForecastView: View {
    let forecast: Forecast<DayWeather>?
    
    var body: some View {
        if let forecast {
            List {
                ForEach(forecast.startIndex..<forecast.endIndex, id: \.self) { indx in
                    DayForecastView(date: forecast[indx].date,
                                    symbolName: forecast[indx].symbolName,
                                    low: forecast[indx].lowTemperature,
                                    high: forecast[indx].highTemperature)
                }
            }
            .ignoresSafeArea(edges: [.leading, .trailing, .bottom])
            .listStyle(.plain)
        } else {
            EmptyView()
        }
    }
}

struct DayForecastView: View {
    let date: Date
    let symbolName: String
    let low: Measurement<UnitTemperature>
    let high: Measurement<UnitTemperature>

    var body: some View {
        HStack {
            HStack {
                Text(dayOfWeek(from: date))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                
                Image(systemName: symbolName)
                    .imageScale(.large)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.primary, Color.accentColor, Color.orange)
                    .padding(.trailing, 20)
            }
            
            Spacer()
            
            HStack {
                VStack {
                    Text("Low")
                        .font(.caption)
                    Text(low.format())
                        .bold()
                }
                .padding(.trailing, 20)

                VStack {
                    Text("High")
                        .font(.caption)
                    Text(high.format())
                        .bold()
                }
                .padding(.trailing, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Initializers
    
    init(date: Date, symbolName: String, low: Measurement<UnitTemperature>, high: Measurement<UnitTemperature>) {
        self.date = date
        self.symbolName = symbolName
        self.low = low
        self.high = high
    }
    
    // MARK: - Private Utilities
    
    private func dayOfWeek(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date.now
        
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        if day == calendar.component(.day, from: now) && 
           month == calendar.component(.month, from: now) &&
           year == calendar.component(.year, from: now) {
            return "Today"
        }
            

        let formatter = DateFormatter()
        let dow = Calendar.current.component(.weekday, from: date) - 1
        let weekday = formatter.weekdaySymbols[dow]
        
        return weekday
    }
}

#Preview("DayForecastView") {
    DayForecastView(date: .now,
                    symbolName: "cloud.drizzle",
                    low: Measurement(value: 39.0, unit: UnitTemperature.celsius),
                    high: Measurement(value: 32.0, unit: UnitTemperature.celsius))
}
