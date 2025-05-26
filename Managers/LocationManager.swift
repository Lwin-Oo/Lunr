//
//  LocationManager.swift
//  Lunr
//
//  Created by Lwin Oo on 5/26/25.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    private var completion: ((CLLocationCoordinate2D?) -> Void)?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func getCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        self.completion = completion

        #if os(macOS)
        if CLLocationManager.locationServicesEnabled() {
            manager.requestAlwaysAuthorization() // macOS requires Always
            manager.startUpdatingLocation()
        } else {
            completion(nil)
        }
        #else
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            completion(nil)
        default:
            completion(nil)
        }
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else {
            completion?(nil)
            return
        }
        completion?(loc.coordinate)
        completion = nil
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Failed to get location: \(error)")
        completion?(nil)
        completion = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        #if os(macOS)
        if manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            completion?(nil)
            completion = nil
        }
        #endif
    }
}
