//
// Created by Joey Jarosz on 3/6/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import WidgetKit
import SwiftUI
import Kingfisher

// MARK: - The Timeline Provider

struct Provider: TimelineProvider {
    private let weatherByLocation = WeatherByLocation()
    private let defaults = Defaults()

    ///
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), viewModel: createDummy())
    }

    ///
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        if context.isPreview {
            let entry = SimpleEntry(date: Date(), viewModel: createDummy())
            completion(entry)
        } else {
            let entry = SimpleEntry(date: Date(), viewModel: nil)
            completion(entry)
        }
    }

    /// Creates the data that represents the weather at a certain time in the user's current location...
    ///
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        weatherByLocation.getWeather { result in
            var entries: [SimpleEntry] = []

            switch result {
            case .failure:
                entries.append(SimpleEntry(date: Date(), viewModel: nil))

            case .success(let weather):
                entries.append(SimpleEntry(date: Date(), viewModel: WeatherViewModel(with: weather)))
                break
            }

            // Update every 5 minutes...
            var nextRetrival = Date()
            nextRetrival.addTimeInterval(60 * 5)

            let timeline = Timeline(entries: entries, policy: .after(nextRetrival))
            completion(timeline)
        }
    }
}

// MARK: - The Timeline Data

struct SimpleEntry: TimelineEntry {
    let date: Date
    let viewModel: WeatherViewModel?
}

// MARK: - The SwiftUI View

struct WeatherWidgetEntryView : View {
    @Environment(\.widgetFamily) var size

    var entry: Provider.Entry

    fileprivate func createSmall(_ viewModel: WeatherViewModel) -> some View {
        GeometryReader { geometry in
            VStack {
                HStack(alignment: .top, spacing: 0) {
                    ZStack {
                        Color(.clear)

                        KFImage.url(viewModel.iconUrl)
                            .resizable()
                            .clipShape(ContainerRelativeShape().inset(by: 5))
                    }
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5, alignment: .topLeading)

                    VStack {
                        Spacer(minLength: 10)

                        Text(viewModel.temperature)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(viewModel.description)
                            .font(.subheadline)
                            .fontWeight(.thin)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)


                        Spacer(minLength: 0)
                    }
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.width * 0.5, alignment: .center)
                }

                VStack(spacing: 0) {
                    Text(viewModel.city)
                        .font(.title)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(viewModel.state)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            }
        }
    }

    fileprivate func createMedium(_ viewModel: WeatherViewModel) -> some View {
        let formatter = RelativeDateTimeFormatter()

        return GeometryReader { geometry in
            HStack {
                ZStack {
                    Color(.clear)

                    KFImage.url(viewModel.iconUrl)
                        .resizable()
                        .clipShape(ContainerRelativeShape().inset(by: 8))
                }
                .frame(width: geometry.size.height, height: geometry.size.height, alignment: .topLeading)

                VStack {
                    Spacer()

                    VStack(alignment: .center) {
                        Text(viewModel.temperature)
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Checked: \(viewModel.lastCheckedTime, formatter: formatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack {
                        Text(viewModel.description)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    HStack(spacing: 0) {
                        Text("\(viewModel.city), \(viewModel.state)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    Spacer()
                }
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8))
            }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)

            if let viewModel = entry.viewModel {
                switch size {
                case .systemSmall:
                    createSmall(viewModel)
                        .padding(0)
                default:
                    createMedium(viewModel)
                        .padding(0)
                }
            } else {
                Text("No Data")
            }
        }
    }
}

// MARK: - The WIDGET

@main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Simple Weather")
        .description("Shows your local weather.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - SwiftUI Preview

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidgetEntryView(entry: SimpleEntry(date: Date(), viewModel: createDummy()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        WeatherWidgetEntryView(entry: SimpleEntry(date: Date(), viewModel: createDummy()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

// MARK: - Utilities

fileprivate func createDummy() -> WeatherViewModel {
    let location = Location(name: "New York",
                            region: "New York",
                            localtime_epoch: 1615126860)

    let current = Current(observation_time: "07:21 PM",
                          temperature: 41,
                          weather_icons: [
                            "https://assets.weatherstack.com/images/wsymbols01_png_64/wsymbol_0002_sunny_intervals.png"
                          ],
                          weather_descriptions: [
                            "Sunny"
                          ])

    return WeatherViewModel(with: Weather(location: location, current: current))
}
