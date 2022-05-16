//
// Created by Joey Jarosz on 5/15/22.
//
//

import CoreLocationUI
import CoreLocation
import MapKit
import UIKit

class MyViewController: UIViewController {
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var locationButton1: CLLocationButton!

    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationLabel.isHidden = true
        locationButton1.backgroundColor = .green

        locationManager.delegate = self
        
        //
        let button = CLLocationButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.icon = .arrowOutline
        button.backgroundColor = .clear
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: locationButton1.trailingAnchor, constant: 20),
            button.topAnchor.constraint(equalTo: locationButton1.topAnchor)
        ])
    }
    
    @IBAction private func buttonTapped(_ sender: CLLocationButton) {
        locationManager.startUpdatingLocation()
        //locationManager.requestLocation()
    }
}

extension MyViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        default:
            locationManager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { location in
            locationLabel.isHidden = false
            locationLabel.text = "\(location.coordinate.latitude) : \(location.coordinate.longitude)"
            
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Error: \(error)")
    }
}
