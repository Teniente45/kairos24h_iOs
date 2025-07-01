//
//  SeguridadUtils.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//

import Foundation
import CoreLocation
import Network
import os.log

// Clase utilitaria que proporciona validaciones de seguridad como detección de VPN, validación de conexión a Internet y ubicación real.
enum ResultadoUbicacion {
    case ok
    case gpsDesactivado
    case ubicacionSimulada
}

class SeguridadUtils: NSObject {

    static let shared = SeguridadUtils()

    private let locationManager = CLLocationManager()
    private var locationCompletion: ((ResultadoUbicacion) -> Void)?

    // Detecta si el dispositivo está usando una VPN activa mediante interfaces no estándar.
    // Verifica si se está usando una VPN (a través de Network.framework)
    func isUsingVPN() -> Bool {
        let monitor = NWPathMonitor()
        var vpnDetected = false
        let semaphore = DispatchSemaphore(value: 0)

        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.other) && path.availableInterfaces.contains(where: { $0.type == .other }) {
                vpnDetected = true
            }
            monitor.cancel()
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "VPNMonitor")
        monitor.start(queue: queue)
        semaphore.wait()
        return vpnDetected
    }

    // Verifica si hay conexión activa a Internet utilizando Network.framework.
    // Verifica si hay conexión a Internet
    func isInternetAvailable() -> Bool {
        let monitor = NWPathMonitor()
        var isConnected = false
        let semaphore = DispatchSemaphore(value: 0)

        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            monitor.cancel()
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "InternetMonitor")
        monitor.start(queue: queue)
        semaphore.wait()
        return isConnected
    }

    // Inicia la localización y evalúa si el GPS está activado. Se asume que la ubicación es real si se obtiene sin error.
    // Detecta si la ubicación es real o simulada
    func detectarUbicacionReal(completion: @escaping (ResultadoUbicacion) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            os_log("GPS desactivado por el usuario", log: .default, type: .error)
            completion(.gpsDesactivado)
            return
        }

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationCompletion = completion
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    // Devuelve true si la app tiene permisos de localización válidos (WhenInUse o Always).
    // Comprueba si la app tiene permisos de ubicación
    func hasLocationPermission() -> Bool {
        let status = locationManager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    // Lógica principal que evalúa si se permiten los fichajes en función de GPS, IP y configuración. Muestra alertas si falla alguna validación.
    // Comprueba las condiciones de seguridad para permitir fichaje
    func checkSecurity(
        lComGPS: String,
        lComIP: String,
        lBotonesFichajeMovil: String,
        onShowAlert: @escaping (String) -> Void,
        completion: @escaping (Bool) -> Void
    ) {
        let validarGPS = lComGPS == "S"
        let validarIP = lComIP == "S"
        let mostrarBotones = lBotonesFichajeMovil != "N"

        os_log("Validaciones: GPS=%{public}@, IP=%{public}@, Botones=%{public}@",
               log: .default, type: .debug,
               validarGPS.description, validarIP.description, mostrarBotones.description)

        if validarGPS {
            guard hasLocationPermission() else {
                os_log("GPS obligatorio, pero sin permiso", log: .default, type: .error)
                onShowAlert("PROBLEMA GPS")
                completion(false)
                return
            }

            detectarUbicacionReal { resultado in
                switch resultado {
                case .gpsDesactivado:
                    os_log("GPS desactivado", log: .default, type: .error)
                    onShowAlert("PROBLEMA GPS")
                    completion(false)
                case .ubicacionSimulada:
                    os_log("Ubicación simulada detectada", log: .default, type: .error)
                    onShowAlert("UBICACIÓN SIMULADA")
                    completion(false)
                case .ok:
                    if validarIP && self.isUsingVPN() {
                        os_log("VPN detectada y uso de IP obligatorio", log: .default, type: .error)
                        onShowAlert("VPN DETECTADA")
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        } else {
            if validarIP && isUsingVPN() {
                os_log("VPN detectada y uso de IP obligatorio", log: .default, type: .error)
                onShowAlert("VPN DETECTADA")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}

extension SeguridadUtils: CLLocationManagerDelegate {
    // Delegate que recibe ubicaciones del sistema. Si se recibe una válida, se considera que no es simulada.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.last != nil else {
            locationCompletion?(.gpsDesactivado)
            return
        }

        // iOS no expone directamente si es mock, asumimos que es válida
        locationCompletion?(.ok)
    }

    // Delegate que se llama cuando falla la obtención de la ubicación.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("Error al obtener ubicación: %{public}@", log: .default, type: .error, error.localizedDescription)
        locationCompletion?(.gpsDesactivado)
    }
}
