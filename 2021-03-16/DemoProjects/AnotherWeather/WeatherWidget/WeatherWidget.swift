//
// Created by Joey Jarosz on 3/13/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import WidgetKit
import SwiftUI
import Kingfisher

// MARK: - The Timeline Provider

struct Provider: IntentTimelineProvider {
    private let weatherByLocation = WeatherByLocation()
    private let defaults = Defaults()

    func placeholder(in context: Context) -> AnotherEntry {
        AnotherEntry(date: Date(), configuration: ConfigurationIntent(), viewModel: createDummy(), image: UIImage(named: "Dummy"))
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (AnotherEntry) -> ()) {
        if context.isPreview {
            let entry = AnotherEntry(date: Date(), configuration: configuration, viewModel: createDummy(), image: UIImage(named: "Dummy"))
            completion(entry)
        } else {
            let entry = AnotherEntry(date: Date(), configuration: configuration, viewModel: nil)
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var location: String?

        switch configuration.cityState {
        case Enum(rawValue: 1):
            location = "Boulder City, Nevada"
        case Enum(rawValue: 2):
            location = "Las Vegas, Nevada"
        case Enum(rawValue: 3):
            location = "San Diego, California"
        case Enum(rawValue: 4):
            location = "San Francisco, California"
        case Enum(rawValue: 5):
            location = "New York, New York"
        case Enum(rawValue: 6):
            location = "Honolulu, Hawaii"
        default:
            break
        }

        weatherByLocation.getWeather(location: location) { result in
            var entries: [AnotherEntry] = []

            // Update every 5 minutes...
            var nextRetrival = Date()
            nextRetrival.addTimeInterval(60 * 5)

            switch result {
            case .failure:
                entries.append(AnotherEntry(date: Date(), configuration: configuration, viewModel: nil, image: UIImage(named: "Dummy")))
                completion(Timeline(entries: entries, policy: .after(nextRetrival)))

            case .success(let weather):
                let viewModel = WeatherViewModel(with: weather)
                let url = URL(string: weather.current.weather_icons.first!)!
                let imageView = UIImageView(frame: .zero)

                imageView.kf.setImage(with: url) { result in
                    switch result {
                    case .success(let imageResult):
                        entries.append(AnotherEntry(date: Date(), configuration: configuration, viewModel: viewModel, image: imageResult.image))
                    case .failure:
                        break
                    }

                    completion(Timeline(entries: entries, policy: .after(nextRetrival)))
                }
            }
        }
    }
}

// MARK: - The Timeline Data

struct AnotherEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let viewModel: WeatherViewModel?
    var image: UIImage?
}

// MARK: - The SwiftUI View

struct WeatherWidgetEntryView : View {
    @Environment(\.widgetFamily) var size

    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color(.systemBackground)

            if let viewModel = entry.viewModel {
                switch size {
                case .systemSmall:
                    SmallWidget(entry: entry, viewModel: viewModel)
                default:
                    MediumWidget(entry: entry, viewModel: viewModel)
                }
            } else {
                Text("Where?")
            }
        }
    }
}

struct MediumWidget: View {
    let formatter = RelativeDateTimeFormatter()
    let entry: AnotherEntry
    let viewModel: WeatherViewModel

    var body: some View {
        GeometryReader { geometry in
            HStack {
                ZStack {
                    Color(.clear)

                    Image(uiImage: entry.image!)
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
}

struct SmallWidget: View {
    let entry: AnotherEntry
    let viewModel: WeatherViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack(alignment: .top, spacing: 0) {
                    ZStack {
                        Color(.clear)

                        Image(uiImage: entry.image!)
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
}

// MARK: - The WIDGET

@main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Another Weather")
        .description("Shows the weather in a selected city.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - SwiftUI Preview

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidgetEntryView(entry: AnotherEntry(date: Date(), configuration: ConfigurationIntent(), viewModel: createDummy()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        WeatherWidgetEntryView(entry: AnotherEntry(date: Date(), configuration: ConfigurationIntent(), viewModel: createDummy()))
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
