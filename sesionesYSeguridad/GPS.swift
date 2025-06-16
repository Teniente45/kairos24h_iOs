//
//  GPS.swift
//  kairos24h
//
//  Created by Juan López Marín on 13/6/25.
//

import CoreLocation

class GPSUtils: NSObject, CLLocationManagerDelegate {
    static let shared = GPSUtils()

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func obtenerLatitud() -> Double {
        return currentLocation?.coordinate.latitude ?? 0.0
    }

    func obtenerLongitud() -> Double {
        return currentLocation?.coordinate.longitude ?? 0.0
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPSUtils - Error al obtener ubicación: \(error.localizedDescription)")
    }
}
