//
//  ManejoDeSesion.swift
//  kairos24h
//
//  Created by Juan López Marín on 13/6/25.
//


import Foundation
import WebKit

class ManejoDeSesion {
    
    static func onPause() {
        print("ManejoDeSesion - Aplicación en pausa")
    }

    static func onStop(webView: WKWebView?) {
        print("ManejoDeSesion - Aplicación detenida")
        let js = """
        (function() {
            console.log("Simulación de inactividad - onStop");
        })();
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    static func onResume(webView: WKWebView?) {
        print("ManejoDeSesion - Aplicación reanudada")
        let js = """
        (function() {
            console.log("Simulación de reactivación - onResume");
        })();
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    static func obtenerFechaHoraInternet(completion: @escaping (Date?) -> Void) {
        guard let url = URL(string: "https://www.google.com") else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let task = URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse,
               let dateString = httpResponse.allHeaderFields["Date"] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
                formatter.locale = Locale(identifier: "en_US")
                let date = formatter.date(from: dateString)
                DispatchQueue.main.async {
                    completion(date)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
        task.resume()
    }

    static func startActivitySimulationTimer(webView: WKWebView?, sessionTimeout: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: true) { _ in
            print("Simulando actividad en WebView después de \(sessionTimeout) segundos de inactividad")
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
}
