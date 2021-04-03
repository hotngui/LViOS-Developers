//
// Created by Joey Jarosz on 4/2/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import Foundation
import MapKit

/// A basic annotation with some additional information to describe the details of the look...
///
class Place: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let image: UIImage?
    let color: UIColor?

    init(with coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, imageName: String?, color: UIColor?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.color = color

        if let imageName = imageName {
            self.image = UIImage(systemName: imageName)
        } else {
            self.image = nil
        }
    }
}
