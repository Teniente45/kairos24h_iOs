//
//  SeguridadUtils.swift
//  kairos24h
//
//  Created by Juan López Marín on 13/6/25.
//


import Foundation
import CoreLocation
import Network

enum ResultadoUbicacion {
    case ok
    case gpsDesactivado
    case ubicacionSimulada
}

class SeguridadUtils: NSObject, CLLocationManagerDelegate {
    static let shared = SeguridadUtils()
    
    private let monitor = NWPathMonitor()
    private var isInternetReachable = false
    private let locationManager = CLLocationManager()
    private var locationCompletion: ((ResultadoUbicacion) -> Void)?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        monitor.pathUpdateHandler = { path in
            self.isInternetReachable = path.status == .satisfied
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }

    func isUsingVPN() -> Bool {
        // Método aproximado usando interfaces de red activas
        var addresses = [String]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return false }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            if let name = String(validatingUTF8: ptr.pointee.ifa_name), name.contains("utun") || name.contains("ppp") {
                addresses.append(name)
            }
        }

        freeifaddrs(ifaddr)
        return !addresses.isEmpty
    }

    func isInternetAvailable() -> Bool {
        return isInternetReachable
    }

    func hasLocationPermission() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
    }

    func detectarUbicacionReal(completion: @escaping (ResultadoUbicacion) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.gpsDesactivado)
            return
        }

        locationCompletion = completion
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // iOS no permite saber si la ubicación es simulada, así que devolvemos OK si hay una ubicación válida
        if let _ = locations.last {
            locationCompletion?(.ok)
        } else {
            locationCompletion?(.gpsDesactivado)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationCompletion?(.gpsDesactivado)
    }

    func checkSecurity(lComGPS: String, lComIP: String, lBotonesFichajeMovil: String, onShowAlert: (String) -> Void, completion: @escaping (Bool) -> Void) {
        let validarGPS = lComGPS == "S"
        let validarIP = lComIP == "S"

        if validarGPS {
            if !hasLocationPermission() {
                onShowAlert("PROBLEMA GPS")
                completion(false)
                return
            }

            detectarUbicacionReal { resultado in
                switch resultado {
                case .gpsDesactivado:
                    onShowAlert("PROBLEMA GPS")
                    completion(false)
                case .ubicacionSimulada, .ok:
                    if validarIP && self.isUsingVPN() {
                        onShowAlert("VPN DETECTADA")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        } else if validarIP && isUsingVPN() {
            onShowAlert("VPN DETECTADA")
            completion(false)
        } else {
            completion(true)
        }
    }
}
