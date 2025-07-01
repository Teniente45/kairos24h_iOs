//
//  AuthManager.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//

// Clase encargada de gestionar la autenticación del usuario, el almacenamiento seguro de las credenciales en UserDefaults,
// y la validación remota a través de URLSession. Utilizado tanto para login manual como autologin.

import Foundation
import WebKit

struct UserCredentials {
    let usuario: String
    let password: String
    let xEmpleado: String
    let lComGPS: String
    let lComIP: String
    let lBotonesFichajeMovil: String
    let xEntidad: String
    let sEmpleado: String
    let tUrlCPP: String
    let tLogo: String
    let cTipEmp: String
}

class AuthManager {

    static let shared = AuthManager()

    private let defaults = UserDefaults.standard

    private init() {}

    // Recupera las credenciales del usuario almacenadas en UserDefaults
    func getUserCredentials() -> UserCredentials {
        return UserCredentials(
            usuario: defaults.string(forKey: "usuario") ?? "",
            password: defaults.string(forKey: "password") ?? "",
            xEmpleado: defaults.string(forKey: "xEmpleado") ?? "",
            lComGPS: defaults.string(forKey: "lComGPS") ?? "N",
            lComIP: defaults.string(forKey: "lComIP") ?? "N",
            lBotonesFichajeMovil: defaults.string(forKey: "lBotonesFichajeMovil") ?? "N",
            xEntidad: defaults.string(forKey: "xEntidad") ?? "",
            sEmpleado: defaults.string(forKey: "sEmpleado") ?? "",
            tUrlCPP: defaults.string(forKey: "tUrlCPP") ?? "",
            tLogo: defaults.string(forKey: "tLogo") ?? "",
            cTipEmp: defaults.string(forKey: "cTipEmp") ?? ""
        )
    }

    // Guarda todas las credenciales del usuario en UserDefaults tras un login exitoso
    func saveUserCredentials(
        usuario: String,
        password: String,
        xEmpleado: String,
        lComGPS: String,
        lComIP: String,
        lBotonesFichajeMovil: String,
        xEntidad: String,
        sEmpleado: String,
        tUrlCPP: String,
        tLogo: String,
        cTipEmp: String
    ) {
        defaults.set(usuario, forKey: "usuario")
        defaults.set(password, forKey: "password")
        defaults.set(xEmpleado, forKey: "xEmpleado")
        defaults.set(lComGPS, forKey: "lComGPS")
        defaults.set(lComIP, forKey: "lComIP")
        defaults.set(lBotonesFichajeMovil, forKey: "lBotonesFichajeMovil")
        defaults.set(xEntidad, forKey: "xEntidad")
        defaults.set(sEmpleado, forKey: "sEmpleado")
        defaults.set(tUrlCPP, forKey: "tUrlCPP")
        defaults.set(tLogo, forKey: "tLogo")
        defaults.set(cTipEmp, forKey: "cTipEmp")
    }

    // Elimina todos los datos del usuario almacenados en UserDefaults (se usa en logout)
    func clearAllUserData() {
        let keys = [
            "usuario", "password", "xEmpleado",
            "lComGPS", "lComIP", "lBotonesFichajeMovil",
            "xEntidad", "sEmpleado", "tUrlCPP",
            "tLogo", "cTipEmp"
        ]
        keys.forEach { defaults.removeObject(forKey: $0) }

        // Elimina cookies y datos del WKWebView
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                print("✅ Datos del WKWebView eliminados")
            }
        }
    }

    // Realiza una petición HTTP para autenticar al usuario y devuelve las credenciales completas si es exitoso
    func authenticateUser(usuario: String, password: String, completion: @escaping (Bool, UserCredentials?) -> Void) {
        guard let url = URL(string: "\(WebViewURL.LOGINAPK)&cUsuario=\(usuario)&tPassword=\(password)") else {
            completion(false, nil)
            return
        }

        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("AuthManager Error: \(error)")
                completion(false, nil)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(false, nil)
                return
            }

            let code = json["code"] as? Int ?? -1
            if code == 1 {
                // Construye el objeto UserCredentials con los datos devueltos por el backend
                let credentials = UserCredentials(
                    usuario: usuario,
                    password: password,
                    xEmpleado: String(describing: json["xEmpleado"] ?? ""),
                    lComGPS: json["lComGPS"] as? String ?? "S",
                    lComIP: json["lComIP"] as? String ?? "S",
                    lBotonesFichajeMovil: json["lBotonesFichajeMovil"] as? String ?? "S",
                    xEntidad: String(describing: json["xEntidad"] ?? ""),
                    sEmpleado: json["sEmpleado"] as? String ?? "",
                    tUrlCPP: json["tUrlCPP"] as? String ?? "",
                    tLogo: json["tLogo"] as? String ?? "",
                    cTipEmp: json["cTipEmp"] as? String ?? ""
                )
                completion(true, credentials)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
}
