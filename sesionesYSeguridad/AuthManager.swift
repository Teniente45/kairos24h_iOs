//
//  AuthManager.swift
//  kairos24h
//
//  Created by Juan López Marín on 13/6/25.
//


import Foundation

private let loginURL = "https://ejemplo.com/loginAPK"

struct UserCredentials {
    let usuario: String
    let password: String
    let xEmpleado: String?
    let lComGPS: String
    let lComIP: String
    let lBotonesFichajeMovil: String
    let xEntidad: String?
    let sEmpleado: String
    let tUrlCPP: String
    let tLogo: String
    let cTipEmp: String
}

class AuthManager {
    
    static func getUserCredentials() -> UserCredentials {
        let defaults = UserDefaults.standard
        let usuario = defaults.string(forKey: "usuario") ?? ""
        let password = defaults.string(forKey: "password") ?? ""
        let xEmpleado = defaults.string(forKey: "xEmpleado")
        let lComGPS = defaults.string(forKey: "lComGPS") ?? "N"
        let lComIP = defaults.string(forKey: "lComIP") ?? "N"
        let lBotonesFichajeMovil = defaults.string(forKey: "lBotonesFichajeMovil") ?? "N"
        let xEntidad = defaults.string(forKey: "xEntidad")
        let sEmpleado = defaults.string(forKey: "sEmpleado") ?? ""
        let tUrlCPP = defaults.string(forKey: "tUrlCPP") ?? ""
        let tLogo = defaults.string(forKey: "tLogo") ?? ""
        let cTipEmp = defaults.string(forKey: "cTipEmp") ?? ""
        
        print("getUserCredentials - usuario=\(usuario), password=\(password), xEmpleado=\(String(describing: xEmpleado)), lComGPS=\(lComGPS), lComIP=\(lComIP), lBotonesFichajeMovil=\(lBotonesFichajeMovil), xEntidad=\(String(describing: xEntidad)), sEmpleado=\(sEmpleado), tUrlCPP=\(tUrlCPP), tLogo=\(tLogo), cTipEmp=\(cTipEmp)")
        
        return UserCredentials(
            usuario: usuario,
            password: password,
            xEmpleado: xEmpleado,
            lComGPS: lComGPS,
            lComIP: lComIP,
            lBotonesFichajeMovil: lBotonesFichajeMovil,
            xEntidad: xEntidad,
            sEmpleado: sEmpleado,
            tUrlCPP: tUrlCPP,
            tLogo: tLogo,
            cTipEmp: cTipEmp
        )
    }
    
    static func saveUserCredentials(
        usuario: String,
        password: String,
        xEmpleado: String?,
        lComGPS: String,
        lComIP: String,
        lBotonesFichajeMovil: String,
        xEntidad: String?,
        sEmpleado: String,
        tUrlCPP: String,
        tLogo: String,
        cTipEmp: String
    ) {
        let defaults = UserDefaults.standard
        defaults.setValue(usuario, forKey: "usuario")
        defaults.setValue(password, forKey: "password")
        if let xEmpleado = xEmpleado {
            defaults.setValue(xEmpleado, forKey: "xEmpleado")
        }
        defaults.setValue(lComGPS, forKey: "lComGPS")
        defaults.setValue(lComIP, forKey: "lComIP")
        defaults.setValue(lBotonesFichajeMovil, forKey: "lBotonesFichajeMovil")
        if let xEntidad = xEntidad {
            defaults.setValue(xEntidad, forKey: "xEntidad")
        }
        defaults.setValue(sEmpleado, forKey: "sEmpleado")
        defaults.setValue(tUrlCPP, forKey: "tUrlCPP")
        defaults.setValue(tLogo, forKey: "tLogo")
        defaults.setValue(cTipEmp, forKey: "cTipEmp")
        
        print("saveUserCredentials - usuario=\(usuario), password=\(password), xEmpleado=\(String(describing: xEmpleado)), lComGPS=\(lComGPS), lComIP=\(lComIP), lBotonesFichajeMovil=\(lBotonesFichajeMovil), xEntidad=\(String(describing: xEntidad)), sEmpleado=\(sEmpleado), tUrlCPP=\(tUrlCPP), tLogo=\(tLogo), cTipEmp=\(cTipEmp)")
    }
    
    static func authenticateUser(usuario: String, password: String, completion: @escaping (Bool, UserCredentials?) -> Void) {
        let urlString = "\(loginURL)&cUsuario=\(usuario)&tPassword=\(password)"
        guard let url = URL(string: urlString) else {
            print("AuthManager - URL inválida: \(urlString)")
            DispatchQueue.main.async {
                completion(false, nil)
            }
            return
        }
        
        print("AuthManager - URL: \(urlString)")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("AuthManager - Error de autenticación: \(error)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("AuthManager - Respuesta no HTTP")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("AuthManager - Request failed with status: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            guard let data = data else {
                print("AuthManager - No data received")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("AuthManager - Response Body: \(jsonResponse)")
                    let code = jsonResponse["code"] as? Int ?? -1
                    let xEmpleado = jsonResponse["xEmpleado"] as? String
                    if code == 1 {
                        let lComGPS = jsonResponse["lComGPS"] as? String ?? "S"
                        let lComIP = jsonResponse["lComIP"] as? String ?? "S"
                        let lBotonesFichajeMovil = jsonResponse["lBotonesFichajeMovil"] as? String ?? "S"
                        let xEntidad = jsonResponse["xEntidad"] as? String
                        let sEmpleado = jsonResponse["sEmpleado"] as? String ?? ""
                        let tUrlCPP = jsonResponse["tUrlCPP"] as? String ?? ""
                        let tLogo = jsonResponse["tLogo"] as? String ?? ""
                        let cTipEmp = jsonResponse["cTipEmp"] as? String ?? ""
                        
                        let credentials = UserCredentials(
                            usuario: usuario,
                            password: password,
                            xEmpleado: xEmpleado,
                            lComGPS: lComGPS,
                            lComIP: lComIP,
                            lBotonesFichajeMovil: lBotonesFichajeMovil,
                            xEntidad: xEntidad,
                            sEmpleado: sEmpleado,
                            tUrlCPP: tUrlCPP,
                            tLogo: tLogo,
                            cTipEmp: cTipEmp
                        )
                        DispatchQueue.main.async {
                            completion(true, credentials)
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(false, nil)
                        }
                    }
                } else {
                    print("AuthManager - JSON no es un diccionario válido")
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                }
            } catch {
                print("AuthManager - Error parsing JSON: \(error)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
        task.resume()
    }
    
    static func clearAllUserData() {
        let defaults = UserDefaults.standard
        let keys = ["usuario", "password", "xEmpleado", "lComGPS", "lComIP", "lBotonesFichajeMovil", "xEntidad", "sEmpleado", "tUrlCPP", "tLogo", "cTipEmp"]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        print("AuthManager - All user data cleared from UserDefaults")
    }
}
