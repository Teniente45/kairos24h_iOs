//
//  URLs.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//  Todos los derechos reservados.
//
//  Este archivo forma parte de la aplicación Kairos24h (iOS).
//

import SwiftUI

// MARK: - ImagenesMovil: Acceso centralizado a logos
// Esta estructura agrupa los logos utilizados en la app, tanto locales como remotos

struct ImagenesMovil {

    // Logo principal del cliente mostrado en el login
    static let logoCliente: Image? = {
        return Image("kairos24h")
    }()

    static let logoDesarrolladora: Image? = {
        guard let uiImage = UIImage(named: "logo_desarrolladora") else { return nil }
        return Image(uiImage: uiImage)
    }()

    // Estilos de tamaño para los logos
    struct LogoEstilos {
        // Tamaño del logo del cliente
        static let logoSize: CGSize = CGSize(width: 280, height: 280)
        // Tamaño del logo de la desarrolladora
        static let logoDesarrolladoraSize: CGSize = CGSize(width: 200, height: 75)
    }

    // Carga remota del logo del cliente (si viene del backend)
    static func getLogoClienteURL() -> URL? {
        let tLogo = AuthManager.shared.getUserCredentials().tLogo
        guard !tLogo.isEmpty, tLogo != "null" else {
            return nil
        }
        return URL(string: tLogo)
    }

    // Método para cargar el logo del cliente desde la red o usar el logo local como fallback
    static func cargarLogoCliente(completion: @escaping (Image?) -> Void) {
        if let url = getLogoClienteURL() {
            // Si hay URL válida, se descarga la imagen
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let uiImage = UIImage(data: data) else {
                    // Si hay error al descargar, usa el logo local
                    DispatchQueue.main.async {
                        completion(logoCliente)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(Image(uiImage: uiImage))
                }
            }.resume()
        } else {
            // Si no hay URL, usa directamente el logo local
            completion(logoCliente)
        }
    }
}


// MARK: - WebViewURL
// Define URLs base y de login para la WebView

struct WebViewURL {
    static let host = "https://democontrolhorario.kairos24h.es" // Dominio base de la app
    static let entryPoint = "/index.php" // Punto de entrada PHP
    static let urlUsada = "\(host)\(entryPoint)" // URL combinada
    static let actionLogin = "r=wsExterno/loginExterno" // Acción de login por URL
    static let loginAPK = "\(urlUsada)?\(actionLogin)" // URL completa de login
    static let LOGINAPK = loginAPK // Alias redundante
}


// MARK: - BuildURLMovil
// Construcción dinámica de URLs según el usuario autenticado

struct BuildURLMovil {

    // Devuelve el host definido por el usuario o el default si no hay ninguno
    static func getHost() -> String {
        let tUrlCPP = AuthManager.shared.getUserCredentials().tUrlCPP
        let hostFinal = (!tUrlCPP.isEmpty && tUrlCPP != "null") ? tUrlCPP : WebViewURL.host
        print("Host seleccionado: \(hostFinal)")
        return hostFinal
    }

    static let entryPoint = "/index.php" // Punto de entrada estándar

    // Devuelve la URL base usada en toda la app
    static func getURLUsada() -> String {
        return getHost() + entryPoint + "?"
    }

    // Acciones de distintas pantallas del sistema (algunas aún no están definidas)
    static let actionForgotPass = "r=site/solicitudRestablecerClave"
    static let actionLogin = "r=site/index"

    // AÑADIR RESTO DE FUNCIONES

    // Métodos para obtener URLs completas con las acciones definidas
    static func getIndex() -> String { getURLUsada() + actionLogin }
    static func getForgotPassword() -> String { getURLUsada() + actionForgotPass }


    // Parámetros estáticos adicionales para las URLs
    static let xGrupo = ""
    static let cKiosko = ""
    static let cFicOri = "APP"

    // Genera la cadena de parámetros adicionales a incluir en las URLs
    static func getStaticParams() -> String {
        let creds = AuthManager.shared.getUserCredentials()
        let xEntidad = creds.xEntidad ?? ""
        let xEmpleado = creds.xEmpleado ?? ""
        return "&xGrupo=\(xGrupo)&xEntidad=\(xEntidad)&xEmpleado=\(xEmpleado)&cKiosko=\(cKiosko)&cFicOri=\(cFicOri)"
    }
}

// Extensión para comprobar si un String? es nulo o vacío
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
