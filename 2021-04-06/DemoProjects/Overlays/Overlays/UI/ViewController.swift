//
// Created by Joey Jarosz on 4/2/21.
// Copyright © 2021 hot-n-GUI, LLC. All rights reserved.
//

import UIKit
import MapKit

/// A sample screen that contains a mapView that takes up the entire screen and demonstrates several types of _overlays_.
///
class ViewController: UIViewController {
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var blurView: UIVisualEffectView!
    @IBOutlet private weak var circleSwitch: UISwitch!
    @IBOutlet private weak var directionsSwitch: UISwitch!
    @IBOutlet private weak var busyIndicator: UIActivityIndicatorView!

    private var circle: MKCircle?
    private var routes: [MyRouteLine] = []

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setCenter(for: mapView)
        addAnnotations(for: mapView)

        blurView.layer.cornerRadius = 8.0
        blurView.layer.masksToBounds = true
    }

    // MARK: - Actions / Selectors

    @IBAction
    private func circleSwitched(_ sender: UISwitch) {
        if sender.isOn {
            circle = addCircle(for: mapView)
        } else {
            if let circle = self.circle {
                remove(circle: circle, for: mapView)
                self.circle = nil
            }
        }
    }

    @IBAction func directionsSwitched(_ sender: UISwitch) {
        if sender.isOn {
            if let start = Sample.data.first, let end = Sample.data.last {
                getDirections(for: mapView, start: start.coordinate, end: end.coordinate)
            }
        } else {
            routes.forEach { mapView.removeOverlay($0) }
            routes.removeAll()
        }
    }

    // MARK: - Private Utilities

    private func setCenter(for mapView: MKMapView, animated: Bool = false) {
        if let place = Sample.data.first {
            let region = MKCoordinateRegion(center: place.coordinate, latitudinalMeters: 9_000, longitudinalMeters: 9_000)
            mapView.setRegion(region, animated: animated)
        }
    }

    private func addAnnotations(for mapView: MKMapView) {
        Sample.data.forEach { place in
            mapView.addAnnotation(place)
        }
    }

    private func addCircle(for mapView: MKMapView) -> MKCircle? {
        if let place = Sample.data.first {
            let circle = MKCircle(center: place.coordinate, radius: 2000)

            mapView.addOverlay(circle)
            return circle
        }

        return nil
    }

    private func remove(circle: MKCircle, for mapView: MKMapView) {
        mapView.removeOverlay(circle)
    }

    ///
    ///
    /// - Parameters:
    ///   - mapView: The mapview to receive the shapes that represent the possible routes
    ///   - start: The starting location
    ///   - end: The destination location
    ///
    private func getDirections(for mapView: MKMapView, start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end)

        /// Setup a _request_ to retrive directions between two locations...
        let request = MKDirections.Request()

        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: endPlacemark)
        request.requestsAlternateRoutes = true
        request.transportType = .automobile

        /// Set the _request_ to Apple's servers and wait for a response... We'll ignore errors in this example code..
        let directions = MKDirections(request: request)
        busyIndicator.startAnimating()

        directions.calculate { [weak self] response, error in
            self?.busyIndicator.stopAnimating()

            guard let response = response else {
                return
            }

            /// Let's sort the results by the expected trave time, so we can distinguish them on the screen with differnet colors...
            let sortedRoutes = response.routes.sorted { lhs, rhs -> Bool in
                return lhs.expectedTravelTime < rhs.expectedTravelTime
            }

            /// For each alternate route found we create our own overlay object, indicating the first one since its the quickest route...
            for (index, route) in sortedRoutes.enumerated() {
                let routeLine = MyRouteLine(polyline: route.polyline, isPrimary: (index == 0))
                self?.routes.append(routeLine)

                mapView.addOverlay(routeLine)
                //mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
}

// MARK: - Map Support

extension ViewController: MKMapViewDelegate {
    /// Handle rendering of overlays
    ///
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        /// Handle our circles
        if let overlay = overlay as? MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay)

            circleRenderer.strokeColor = .systemPurple
            circleRenderer.fillColor = UIColor.systemPurple.withAlphaComponent(0.1)
            circleRenderer.lineWidth = 0.5
            circleRenderer.alpha = 1.0

            return circleRenderer
        }

        /// Handle routes
        if let routeLine = overlay as? MyRouteLine {
            let renderer = MKPolylineRenderer(polyline: routeLine.polyline)
            renderer.strokeColor = routeLine.color

            return renderer
        }

        return MKOverlayRenderer()
    }

    /// Handle rendering of markers
    ///
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Place {
            let view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "PlaceMarker")

            view.markerTintColor = annotation.color
            view.glyphImage = annotation.image
            view.glyphTintColor = UIColor.systemBackground

            return view
        }

        return nil
    }
}
