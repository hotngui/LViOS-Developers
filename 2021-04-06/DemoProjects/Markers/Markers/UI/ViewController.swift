//
// Created by Joey Jarosz on 4/2/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit
import MapKit

/// A simple screen that contains a mapView that takes up the entire screen.
///
class ViewController: UIViewController {
    @IBOutlet private weak var mapView: MKMapView!

    private enum Style: Int {
        case oldSchool
        case newSchool
    }

    private var style: Style = .oldSchool

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        addAnnotations(for: mapView)
        setCenter(for: mapView)
    }

    @IBAction
    private func segmentValueChanged(_ sender: UISegmentedControl) {
        style = (sender.selectedSegmentIndex == 1 ? .newSchool : .oldSchool)
        resetAnnotations(for: mapView)
    }

    // MARK: - Private Utilities

    private func setCenter(for mapView: MKMapView, animated: Bool = false) {
        if let center = Sample.data.first {
            let region = MKCoordinateRegion(center: center.coordinate, latitudinalMeters: 10_000, longitudinalMeters: 10_000)
            mapView.setRegion(region, animated: animated)
        }
    }

    private func addAnnotations(for mapView: MKMapView) {
        Sample.data.forEach { place in
            mapView.addAnnotation(place)
        }
    }

    private func resetAnnotations(for mapView: MKMapView) {
        mapView.removeAnnotations(mapView.annotations)
        addAnnotations(for: mapView)
    }
}

// MARK: - Map Support

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Place {
            switch style {
            case .oldSchool:
                let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "PlacePin")
                view.pinTintColor = annotation.color
                view.canShowCallout = true
                return view

            case .newSchool:
                let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "PlaceMarker")
                view.markerTintColor = annotation.color
                view.glyphImage = annotation.image
                view.glyphTintColor = UIColor.systemBackground
                return view
            }
        }

        return nil
    }
}

