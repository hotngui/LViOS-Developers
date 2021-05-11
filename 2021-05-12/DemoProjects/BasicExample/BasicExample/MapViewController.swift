//
// Created by Joey Jarosz on 5/10/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    @IBOutlet private weak var mapView: MKMapView!

    private lazy var locations: [Location] = {
        return LocationResults.loadSampleData()
    }()

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let center = CLLocationCoordinate2D(latitude: 36.121417, longitude: -115.167791)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 10_000, longitudinalMeters: 10_000)

        mapView.setRegion(region, animated: false)
        mapView.delegate = self

        addAnnotations(for: mapView)
    }

    // MARK: - Private Utilities

    private func addAnnotations(for mapView: MKMapView) {
        locations.forEach { location in
            let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let place = Place(with: coord, type: location.type, title: location.name, subtitle: location.address)

            mapView.addAnnotation(place)
        }
    }
}

// MARK: - Marker Items

class Place: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let type: Location.BusinessType
    let title: String?
    let subtitle: String?

    init(with coordinate: CLLocationCoordinate2D, type: Location.BusinessType, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.type = type
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - MapView Delegate Implementation

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Place {
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "PlaceMarker")

            switch annotation.type {
            case .casino:
                view.markerTintColor = .systemBlue
                view.glyphTintColor = UIColor.systemBackground
                view.glyphImage = UIImage(systemName: "building.columns.fill")
                view.accessibilityLabel = annotation.title
                view.accessibilityValue = "Casino"

            case .hospital:
                view.markerTintColor = .systemRed
                view.glyphTintColor = UIColor.systemBackground
                view.glyphImage = UIImage(systemName: "cross.fill")
                view.accessibilityLabel = annotation.title
                view.accessibilityValue = "Hospital"
            }

            return view
        }

        return nil
    }
}

