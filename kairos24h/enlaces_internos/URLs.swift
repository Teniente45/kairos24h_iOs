//
//  URLs.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//  Copyright © 2025 Juan López. All rights reserved.
//

import UIKit

class ImagenesMovil {
    static let logoCliente = UIImage(named: "kairos24h")
    static let logoDesarrolladora = UIImage(named: "logo_i3data")

    static func getLogoClienteXPrograma() -> String? {
        let tLogo = AuthManager.shared.getUserCredentials().tLogo
        if !tLogo.isEmpty && tLogo.lowercased() != "null" {
            return tLogo
        }
        return nil
    }

    static func logoClienteRemoto(view: UIImageView) {
        if let logoUrlString = getLogoClienteXPrograma(), let url = URL(string: logoUrlString) {
            // Load image asynchronously from URL with placeholder
            // Using URLSession for simplicity; in production consider using libraries like SDWebImage or Kingfisher
            let placeholder = UIImage(named: "kairos24h")
            view.image = placeholder
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        view.image = image
                    }
                } else {
                    DispatchQueue.main.async {
                        view.image = placeholder
                    }
                }
            }.resume()
        } else {
            view.image = UIImage(named: "kairos24h")
        }
    }
}

struct WebViewURL {
    static let host = "https://beimancpp.tucitamedica.es"
    static let entryPoint = "/index.php"
    static let urlUsada = host + entryPoint

    static let actionLogin = "r=wsExterno/loginExterno"

    static let loginAPK = urlUsada + "?" + actionLogin
}

struct BuildURLmovil {
    private static func getHost() -> String {
        let tUrlCPP = AuthManager.shared.getUserCredentials().tUrlCPP
        let hostFinal: String
        if !tUrlCPP.isEmpty && tUrlCPP.lowercased() != "null" {
            hostFinal = tUrlCPP
        } else {
            hostFinal = WebViewURL.host
        }
        print("BuildURLmovil - Host seleccionado: \(hostFinal)")
        return hostFinal
    }

    private static let entryPoint = "/index.php"

    private static func getURLUsada() -> String {
        return getHost() + entryPoint + "?"
    }

    private static let actionForgotPass = "r=site/solicitudRestablecerClave"
    private static let actionLogin = "r=site/index"
    private static let actionFichaje = "r=explotacion/creaFichaje"
    private static let actionConsultar = "r=explotacion/consultarExplotacion"

    private static let actionConsultHorario = "r=wsExterno/consultarHorarioExterno"
    private static let actionConsultFicDia = "r=wsExterno/consultarFichajesExterno"
    private static let actionConsultAlertas = "r=wsExterno/consultarAlertasExterno"

    static func getIndex() -> String {
        return getURLUsada() + actionLogin
    }

    static func getForgotPassword() -> String {
        return getURLUsada() + actionForgotPass
    }

    static func getFichaje() -> String {
        let url = getURLUsada() + actionConsultar + "&cTipExp=FICHAJE"
        print("URL_Fichaje - URL generada: \(url)")
        return url
    }

    static func getIncidencia() -> String {
        let url = getURLUsada() + actionConsultar + "&cTipExp=INCIDENCIA&cOpcionVisual=INCBAN"
        print("URL_Incidencia - URL generada: \(url)")
        return url
    }

    static func getHorarios() -> String {
        let url = getURLUsada() + actionConsultar + "&cTipExp=HORARIO&cModoVisual=HORMEN"
        print("URL_Horarios - URL generada: \(url)")
        return url
    }

    static func getSolicitudes() -> String {
        let url = getURLUsada() + actionConsultar + "&cTipExp=SOLICITUD"
        print("URL_Solicitudes - URL generada: \(url)")
        return url
    }

    private static let xGrupo = ""
    private static let cKiosko = ""
    private static let cFicOri = "APP"

    private static func getStaticParams() -> String {
        let creds = AuthManager.shared.getUserCredentials()
        let xEntidad = creds.xEntidad ?? ""
        let xEmpleado = creds.xEmpleado ?? ""
        return "&xGrupo=\(xGrupo)" +
               "&xEntidad=\(xEntidad)" +
               "&xEmpleado=\(xEmpleado)" +
               "&cKiosko=\(cKiosko)" +
               "&cFicOri=\(cFicOri)"
    }

    static func getCrearFichaje() -> String {
        return getURLUsada() + actionFichaje + getStaticParams()
    }

    static func getMostrarHorarios() -> String {
        return getURLUsada() + actionConsultHorario + getStaticParams()
    }

    static func getMostrarFichajes() -> String {
        return getURLUsada() + actionConsultFicDia + getStaticParams()
    }

    static func getMostrarAlertas() -> String {
        return getURLUsada() + actionConsultAlertas + getStaticParams()
    }
}


// Dummy AuthManager singleton for context
// In your project, this should be replaced by your actual AuthManager implementation
class AuthManager {
    static let shared = AuthManager()
    private init() {}

    func getUserCredentials() -> UserCredentials {
        // Return mock or actual user credentials
        return UserCredentials()
    }
}

struct UserCredentials {
    var tLogo: String = ""
    var tUrlCPP: String = ""
    var xEntidad: String? = ""
    var xEmpleado: String? = ""
}
