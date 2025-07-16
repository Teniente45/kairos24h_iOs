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
    }

    // Solicita permiso de ubicación al usuario y comienza a actualizar la ubicación actual.
    func solicitarPermisoYComenzarActualizacion() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    // Devuelve la latitud actual del dispositivo si está disponible, o 0.0 si no lo está.
    func obtenerLatitud() -> Double {
        return currentLocation?.coordinate.latitude ?? 0.0
    }

    // Devuelve la longitud actual del dispositivo si está disponible, o 0.0 si no lo está.
    func obtenerLongitud() -> Double {
        return currentLocation?.coordinate.longitude ?? 0.0
    }

    // Delegado que se llama cuando se actualiza la ubicación del dispositivo.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    // Delegado que se llama cuando ocurre un error al intentar obtener la ubicación.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPSUtils - Error al obtener ubicación: \(error.localizedDescription)")
    }
    // Devuelve las coordenadas actuales como CLLocationCoordinate2D y las imprime en consola.
    func obtenerCoordenadas() -> CLLocationCoordinate2D? {
        let coord = currentLocation?.coordinate
        print("📍 Coordenadas actuales: \(String(describing: coord))")
        return coord
    }
}
