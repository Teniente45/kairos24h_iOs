//
//  SolapaWebView.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//

import SwiftUI
import WebKit

struct CabeceraUsuarioView: View {
    @Binding var showLogoutDialog: Bool
    @Binding var navegar: Bool

    var body: some View {
        ZStack {
            Color(red: 0xE2 / 255.0, green: 0xE4 / 255.0, blue: 0xE5 / 255.0)
                .ignoresSafeArea(.container, edges: .top)

            HStack {
                HStack(spacing: 8) {
                    Image("icono_usuario")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text((AuthManager.shared.getUserCredentials().usuario ?? "").uppercased())
                        .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71))
                        .font(.system(size: 14, weight: .medium))
                }

                Spacer()

                Button(action: {
                    showLogoutDialog = true
                }) {
                    Image("ic_cerrar32")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 5)
            .frame(height: 30)
        }
        .frame(height: 30)
        .alert(isPresented: $showLogoutDialog) {
            Alert(
                title: Text("¿Quieres cerrar la sesión?"),
                primaryButton: .destructive(Text("Sí")) {
                    AuthManager.shared.clearAllUserData()
                    navegar = true
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
}

struct SolapaWebView: View {
    let webView: WKWebView
    let onClose: () -> Void
    @Binding var mostrarLogin: Bool

    @State private var showLogoutDialog = false
    @State private var navegar = false
    let cUsuario = AuthManager.shared.getUserCredentials().usuario
    
    // Con esto puedo cambiar el tamaño de los iconos de la barra de navegación
    let iconoBarraInferiorAltura: CGFloat = 36
    
    private func BarraInferiorIcono(nombre: String) -> some View {
        Image(nombre)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: iconoBarraInferiorAltura)
    }

    var body: some View {
        VStack(spacing: 0) {
            CabeceraUsuarioView(showLogoutDialog: $showLogoutDialog, navegar: $navegar)

            ScrollView {
                VStack(spacing: 5) {
                    let tLogo = AuthManager.shared.getUserCredentials().tLogo
                    if !tLogo.isEmpty,
                       tLogo.lowercased() != "null",
                       let url = URL(string: tLogo),
                       let data = try? Data(contentsOf: url),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)

                    } else if let logoCliente = ImagenesMovil.logoCliente {
                        logoCliente
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 130)
                            .padding(.top, -20)
                            .padding(.bottom, -20)
                    }

                    MiHorarioView()
                    
                    Spacer().frame(height: 40)
                    
                    BotonesFichajeView(
                        webView: webView,
                        onFichaje: { tipo in
                            print("✅ Fichaje completado: \(tipo)")
                        },
                        onShowAlert: { mensaje in
                            print("⚠️ Alerta mostrada al usuario: \(mensaje)")
                        }
                    )

                    if let logoDev = ImagenesMovil.logoDesarrolladora {
                        logoDev
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 75)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .zIndex(2)
            
            // Barra de navegación del bottom
            ZStack {
                Color(red: 0xE2 / 255.0, green: 0xE4 / 255.0, blue: 0xE5 / 255.0)

                HStack(spacing: 0) {
                    Spacer()
                    BarraInferiorIcono(nombre: "ic_home32_2")
                    Spacer()
                    BarraInferiorIcono(nombre: "ic_fichajes32")
                    Spacer()
                    BarraInferiorIcono(nombre: "ic_incidencia32")
                    Spacer()
                    BarraInferiorIcono(nombre: "ic_horario32")
                    Spacer()
                    BarraInferiorIcono(nombre: "solicitudes32")
                    Spacer()
                }
            }
            .frame(height: 50)
        }
        .background(
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()
                    Color(red: 0xE2 / 255.0, green: 0xE4 / 255.0, blue: 0xE5 / 255.0)
                        .frame(height: geometry.safeAreaInsets.bottom)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
        )
        .navigationDestination(isPresented: $navegar) {
            PaginaPrincipalViewController()
        }
    }

}

// MARK: Funcion que se encarga de mostrar los horarios del usuario logeado
struct MiHorarioView: View {
    @State private var fechaFormateada: String = "Cargando..."
    @State private var horarioTexto: String = "Cargando horario..."

    var body: some View {
        VStack(spacing: 10) {
            Text(fechaFormateada)
                .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71))
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Text(horarioTexto)
                .foregroundColor(
                    horarioTexto.contains("Error") || horarioTexto.contains("No hay")
                    ? .red
                    : Color(red: 0.46, green: 0.60, blue: 0.71)
                )
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(red: 192/255, green: 192/255, blue: 192/255), lineWidth: 1)
        )
        .task {
            await cargarHorario()
        }
    }

    func cargarHorario() async {
        let formateadorServidor = DateFormatter()
        formateadorServidor.dateFormat = "yyyy-MM-dd"
        let formateadorTexto = DateFormatter()
        formateadorTexto.locale = Locale(identifier: "es_ES")
        formateadorTexto.dateFormat = "EEEE, d 'de' MMMM 'de' yyyy"

        do {
            let fecha = try await ManejoDeSesion.shared.obtenerFechaHoraInternetAsync()
            let fechaFormateadaTexto = formateadorTexto.string(from: fecha).capitalized
            let fechaStr = formateadorServidor.string(from: fecha)
            let urlString = BuildURLMovil.getURLHorario() + "&fecha=\(fechaStr)"
            print("📡 URL consultada para el horario: \(urlString)")

            fechaFormateada = fechaFormateadaTexto

            guard let url = URL(string: urlString) else {
                horarioTexto = "URL inválida"
                return
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("🔁 Código de estado HTTP: \(httpResponse.statusCode)")
            }

            let rawString = String(data: data, encoding: .utf8)?
                .replacingOccurrences(of: "\u{feff}", with: "")

            guard let cleanedData = rawString?.data(using: .utf8) else {
                horarioTexto = "Error al limpiar datos"
                return
            }

            let jsonObject = try JSONSerialization.jsonObject(with: cleanedData)
            print("📦 JSON bruto recibido: \(jsonObject)")

            guard let json = jsonObject as? [String: Any] else {
                print("❌ Error: JSON no es un diccionario")
                horarioTexto = "Error al procesar datos"
                return
            }

            guard let dataArray = json["dataHorario"] as? [[String: Any]], let item = dataArray.first else {
                print("⚠️ No se encontró 'dataHorario' o estaba vacío")
                horarioTexto = "No Horario"
                return
            }

            guard let horaIniNum = item["N_HORINI"] as? NSNumber,
                  let horaFinNum = item["N_HORFIN"] as? NSNumber else {
                print("⚠️ Campos N_HORINI o N_HORFIN no disponibles")
                horarioTexto = "No Horario"
                return
            }

            let horaIni = horaIniNum.intValue
            let horaFin = horaFinNum.intValue

            if horaIni == 0 && horaFin == 0 {
                print("⚠️ Ambos valores de horario son 0")
                horarioTexto = "No Horario"
                return
            }

            print("🕒 Hora inicio (N_HORINI): \(horaIni) minutos")
            print("🕒 Hora fin (N_HORFIN): \(horaFin) minutos")

            func minutosAHora(_ minutos: Int) -> String {
                let horas = minutos / 60
                let mins = minutos % 60
                return String(format: "%02d:%02d", horas, mins)
            }

            let horaFormateada = "\(minutosAHora(horaIni)) - \(minutosAHora(horaFin))"
            horarioTexto = horaFormateada
            print("🕘 Horario formateado: \(horaFormateada)")

        } catch {
            horarioTexto = "Error al obtener horario"
        }
    }
}


// MARK: Funcion que se encarga de mostrar los horarios del usuario logeado

// --- Botones de Fichaje adaptados desde Kotlin ---
import Combine
struct BotonesFichajeView: View {
    let webView: WKWebView?
    let onFichaje: (String) -> Void
    let onShowAlert: (String) -> Void
    @State private var ultimoFichajeTimestamp: TimeInterval = 0

    var body: some View {
        VStack {
            BotonFichaje(tipo: "ENTRADA")
            // Espacio vertical entre los dos botones
            Spacer().frame(height: 40)
            BotonFichaje(tipo: "SALIDA")
        }
    }

    @ViewBuilder
    private func BotonFichaje(tipo: String) -> some View {
        Button(action: {
            Task {
                guard !SeguridadUtils.shared.isUsingVPN() else {
                    print("🚫 VPN detectada")
                    onShowAlert("VPN DETECTADA")
                    return
                }

                guard SeguridadUtils.shared.isInternetAvailable() else {
                    print("📡 Sin conexión")
                    onShowAlert("PROBLEMA INTERNET")
                    return
                }

                guard SeguridadUtils.shared.hasLocationPermission() else {
                    print("📍 Sin permiso de localización")
                    onShowAlert("PROBLEMA GPS")
                    return
                }

                SeguridadUtils.shared.detectarUbicacionReal { resultado in
                    switch resultado {
                    case .gpsDesactivado:
                        print("📍 GPS desactivado")
                        onShowAlert("PROBLEMA GPS")
                        return
                    case .ubicacionSimulada:
                        print("🛰️ Ubicación simulada detectada")
                        onShowAlert("POSIBLE UBI FALSA")
                        return
                    case .ok:
                        let ahora = Date().timeIntervalSince1970
                        if ahora - ultimoFichajeTimestamp < 5 {
                            print("⚠️ Doble fichaje prevenido")
                            return
                        }
                        ultimoFichajeTimestamp = ahora

                        print("✅ Fichaje \(tipo) procesado")
                        if let webView = webView {
                            FichajeManager.shared.fichar(tipo: tipo, webView: webView)
                        }
                        onFichaje(tipo)
                    }
                }
            }
        }) {
            HStack {
                Image(tipo == "ENTRADA" ? "fichajeentrada32" : "fichajesalida32")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .padding(.leading, 15)

                Text("Fichaje \(tipo.capitalized)")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 55)
            .background(Color(red: 0.46, green: 0.60, blue: 0.71))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.055, green: 0.282, blue: 0.475), lineWidth: 2))
            .padding(.horizontal, 20)
        }
        .offset(y: tipo == "ENTRADA" ? -20 : -40)
    }
}

struct FichajeManager {
    static let shared = FichajeManager()

    func fichar(tipo: String, webView: WKWebView) {
        guard let coord = GPSUtils.shared.obtenerCoordenadas() else {
            print("❌ Coordenadas no disponibles")
            return
        }

        let xEmpleado = AuthManager.shared.getUserCredentials().xEmpleado
        let cDomFicOri = "APP"
        let cDomTipFic = tipo
        let tCoordX = coord.latitude
        let tCoordY = coord.longitude

        let urlString = BuildURLMovil.getURLFichaje() +
            "&xEmpleado=\(xEmpleado)" +
            "&cDomTipFic=\(cDomTipFic)" +
            "&cDomFicOri=\(cDomFicOri)" +
            "&tCoordX=\(tCoordX)" +
            "&tCoordY=\(tCoordY)"

        print("📤 URL generada para fichaje: \(urlString)")

        let jsCode = """
        window.location.href = '\(urlString)';
        """
        webView.evaluateJavaScript(jsCode) { (result, error) in
            if let error = error {
                print("❌ Error al ejecutar JavaScript para fichaje: \(error)")
            } else {
                print("✅ Fichaje lanzado con éxito desde WebView")
            }
        }
    }
}
