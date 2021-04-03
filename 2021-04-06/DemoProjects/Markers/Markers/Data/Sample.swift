//
// Created by Joey Jarosz on 4/2/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import MapKit

/// Just some sample data to work with for the demo...
///
class Sample {
    static var data: [Place] = [
        Place(with: CLLocationCoordinate2D(latitude: 37.3421602635123, longitude: -121.98795433004663), title: "My Old House", subtitle: "902 Pomeroy Ave", imageName: "house", color: .systemTeal),
        Place(with: CLLocationCoordinate2D(latitude: 37.33186325950212, longitude: -122.03022118771831), title: "Apple", subtitle: "Infinite Loop", imageName: "applelogo", color: .systemBlue),
        Place(with: CLLocationCoordinate2D(latitude: 37.334903499530455, longitude: -122.0087123538398), title: "Apple Park", subtitle: "N. Tantau Ave", imageName: "applelogo", color: .systemBlue)
    ]
}
