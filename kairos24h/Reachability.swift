//
//  Reachability.swift
//  BeimanFederados_iOs
//
//  Created by Juan López Marín on 23/6/25.
//

import Network

/// Clase singleton que permite verificar el estado de la conexión a Internet de forma asíncrona
final class ReachabilityManager {
    static let shared = ReachabilityManager()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Monitor")

    private init() {
        monitor.start(queue: queue)
    }

    /// Verifica si hay conexión a Internet disponible
    /// - Parameter completion: devuelve true si hay conexión, false si no
    func isInternetAvailable(completion: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                completion(path.status == .satisfied)
            }
        }
    }
}
