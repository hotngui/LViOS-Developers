//
// Created by Joey Jarosz on 4/3/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit
import MapKit

class MyRouteLine: NSObject, MKOverlay {
    private let isPrimary: Bool

    let polyline: MKPolyline
    let color: UIColor

    var coordinate: CLLocationCoordinate2D {
        return polyline.coordinate
    }

    var boundingMapRect: MKMapRect {
        return polyline.boundingMapRect
    }

    init(polyline: MKPolyline, isPrimary: Bool) {
        self.polyline = polyline
        self.isPrimary = isPrimary

        self.color = (isPrimary ? UIColor.systemBlue : UIColor.systemBlue.withAlphaComponent(0.3))
    }
}
