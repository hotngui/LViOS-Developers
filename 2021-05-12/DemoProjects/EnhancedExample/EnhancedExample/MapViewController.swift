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

        ///
        /// Since we multiple types of markers, create some custom rotors so the user can more quickly jump to the ones they are interested in hearing about.
        ///
        mapView.accessibilityCustomRotors = [customRotor(for: .hospital), customRotor(for: .casino)]
    }

    // MARK: - Private Utilities

    private func addAnnotations(for mapView: MKMapView) {
        locations.forEach { location in
            let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let place = Place(with: coord, type: location.type, title: location.name, subtitle: location.address)

            mapView.addAnnotation(place)
        }
    }

    private func annotationViews(for type: Location.BusinessType) -> [MKAnnotationView] {
        let views: [MKAnnotationView] = mapView.annotations.compactMap { annotation in
            if let annotation = annotation as? Place {
                if annotation.type == type {
                    return mapView.view(for: annotation)
                }
            }
            return nil
        }

        return views
    }

    // MARK: - Accessibility Support

    private func customRotor(for type: Location.BusinessType) -> UIAccessibilityCustomRotor {
        let name = (type == .casino ? "Casinos" : "Hospitals")

        return UIAccessibilityCustomRotor(name: name) { [unowned self] predicate in
            let currentElement = predicate.currentItem.targetElement as? MKAnnotationView
            let annotations = self.annotationViews(for: type)
            let currentIndex = annotations.firstIndex { $0 == currentElement }
            let targetIndex: Int

            switch predicate.searchDirection {
            case .previous:
                targetIndex = (currentIndex ?? 1) - 1
            case .next:
                targetIndex = (currentIndex ?? -1) + 1
            @unknown default:
                return nil
            }

            guard 0..<annotations.count ~= targetIndex else {
                return nil
            }

            return UIAccessibilityCustomRotorItemResult(targetElement: annotations[targetIndex], targetRange: nil)
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

