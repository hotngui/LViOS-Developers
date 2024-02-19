//
// Created by Joey Jarosz on 2/17/24.
// Copyright (c) 2024 hot-n-GUI, LLC. All rights reserved.
//

import CoreLocation
import OSLog

///
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let logger = Logger(subsystem: "com.hotngui.WeatherKitExample", category: "locationManager")
    private let manager = CLLocationManager()
    
    private var completion: ((CLLocation?) -> Void)?
    
    var location: CLLocation?
    var cityState: String?
    
    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        manager.requestLocation()
    }
    
    private func whereOnEarth() {
        guard let location = location else {
            cityState = nil
            return
        }
        
        let geoCoder = CLGeocoder()
        
        Task {
            do {
                let placemarks = try await geoCoder.reverseGeocodeLocation(location)
                cityState = placemarks.first!.locality! + ", " + placemarks.first!.administrativeArea!
            }
            catch (let error) {
                logger.error("Where the hell are you? \(error)")
                cityState = nil
                return
            }
        }
    }

    // MARK: - CLLocationManagerDelegate Implementation
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        completion?(location)
        
        whereOnEarth()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Could not find you on the earth: \(error.localizedDescription)")

        location = nil
        cityState = nil
        completion = nil
    }
}
