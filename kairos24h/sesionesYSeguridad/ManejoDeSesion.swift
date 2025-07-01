//
//  ManejoDeSesion.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//

import Foundation
import WebKit

/// Clase singleton que gestiona el ciclo de vida y la simulación de actividad del usuario para mantener la sesión activa en una WebView.
class ManejoDeSesion {

    /// Instancia compartida del singleton para acceder globalmente a las funciones de manejo de sesión.
    static let shared = ManejoDeSesion()
    /// Temporizador que simula actividad periódica en la WebView para evitar cierre de sesión por inactividad.
    private var timer: Timer?

    /// Inicializador privado para evitar múltiples instancias de `ManejoDeSesion`.
    private init() {}

    /// Método llamado cuando la aplicación entra en estado de pausa. Actualmente solo imprime un log.
    func onPause() {
        print("ManejoDeSesion: Aplicación en pausa")
    }

    /// Método que simula inactividad en la WebView cuando la aplicación se detiene.
    /// - Parameter webView: Referencia opcional a la WebView donde se ejecuta el JavaScript.
    func onStop(webView: WKWebView?) {
        print("ManejoDeSesion: Aplicación detenida")
        let js = """
        (function() {
            console.log("Simulación de inactividad - onStop");
        })();
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Método que simula una reactivación de la WebView al reanudar la aplicación.
    /// - Parameter webView: Referencia opcional a la WebView donde se ejecuta el JavaScript.
    func onResume(webView: WKWebView?) {
        print("ManejoDeSesion: Aplicación reanudada")
        let js = """
        (function() {
            console.log("Simulación de reactivación - onResume");
        })();
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Obtiene la fecha y hora actual desde la cabecera HTTP de una petición a Google.
    /// - Parameter completion: Bloque que devuelve la fecha obtenida o nil si falla.
    func obtenerFechaHoraInternet(completion: @escaping (Date?) -> Void) {
        guard let url = URL(string: "https://www.google.com") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               let dateString = httpResponse.allHeaderFields["Date"] as? String {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                let date = formatter.date(from: dateString)
                completion(date)
            } else {
                print("Error al obtener fecha de Internet: \(error?.localizedDescription ?? "Desconocido")")
                completion(nil)
            }
        }.resume()
    }

    /// Inicia un temporizador que simula movimientos del ratón en la WebView para mantener la sesión activa.
    /// - Parameters:
    ///   - webView: La WebView donde se simulará la actividad.
    ///   - sessionTimeout: Intervalo de tiempo entre simulaciones.
    func startActivitySimulationTimer(webView: WKWebView?, sessionTimeout: TimeInterval) {
        stopActivitySimulationTimer()

        timer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: true) { _ in
            print("ManejoDeSesion: Simulando actividad en WebView")
            let js = """
            (function() {
                var event = new MouseEvent('mousemove', {
                    bubbles: true,
                    cancelable: true,
                    view: window,
                    clientX: Math.random() * window.innerWidth,
                    clientY: Math.random() * window.innerHeight
                });
                document.body.dispatchEvent(event);
            })();
            """
            webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    /// Detiene e invalida el temporizador de simulación de actividad.
    func stopActivitySimulationTimer() {
        timer?.invalidate()
        timer = nil
    }
}
