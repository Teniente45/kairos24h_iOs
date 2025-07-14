//
//  SolapaWebView.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//

import SwiftUI
import WebKit

// Mark: Barra de usuario con nombre de usuario y boton para cerrar sesión
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

                    Text(AuthManager.shared.getUserCredentials().usuario.uppercased())
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
    @Binding var mostrarSolapa: Bool

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
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 130)
                            .padding(.top, -20)
                            .padding(.bottom, -20)

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
                    Spacer().frame(height: 40)
                    
                    @State var refreshTrigger = 0
                    
                    RecuadroFichajesDia(refreshTrigger: $refreshTrigger)
                    Spacer().frame(height: 40)
                    
                    AlertasDiariasView(
                        onAbrirWebView: { url in
                            let jsCode = "window.location.href = '\(url)';"
                            webView.evaluateJavaScript(jsCode)
                        },
                        hideCuadroParaFichar: {
                            // No se requiere acción adicional en esta vista, se deja vacío
                        },
                        refreshTrigger: .constant(0)
                    )
                    .padding(.bottom, 12)
                    
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
            
            BarraNavBottom(webView: webView, mostrarSolapa: $mostrarSolapa)
        }
    }
}

// Mark: Barra de navegación del bottom
struct BarraNavBottom: View {
    let webView: WKWebView
    @Binding var mostrarSolapa: Bool

    var body: some View {
        ZStack {
            Color(red: 0xE2 / 255.0, green: 0xE4 / 255.0, blue: 0xE5 / 255.0)

            HStack(spacing: 0) {
                Spacer()
                Button {
                    mostrarSolapa = true
                } label: {
                    Image("ic_home32_2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                }
                Spacer()
                Button {
                    mostrarSolapa = false
                    let js = "window.location.href = '\(BuildURLMovil.consultarFichaje())';"
                    webView.evaluateJavaScript(js)
                } label: {
                    Image("ic_fichajes32")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                }
                Spacer()
                Button {
                    mostrarSolapa = false
                    let js = "window.location.href = '\(BuildURLMovil.consultarIncidencia())';"
                    webView.evaluateJavaScript(js)
                } label: {
                    Image("ic_incidencia32")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                }
                Spacer()
                Button {
                    mostrarSolapa = false
                    let js = "window.location.href = '\(BuildURLMovil.consultarHorarios())';"
                    webView.evaluateJavaScript(js)
                } label: {
                    Image("ic_horario32")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                }
                Spacer()
                Button {
                    mostrarSolapa = false
                    let js = "window.location.href = '\(BuildURLMovil.consultarSolicitudes())';"
                    webView.evaluateJavaScript(js)
                } label: {
                    Image("solicitudes32")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                }
                Spacer()
            }
        }
        .frame(height: 50)
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


// MARK: Vista personalizada para mostrar mensajes de alerta de fichaje
struct MensajeAlerta: View {
    let tipo: String
    let onClose: () -> Void

    private var mensaje: String {
        switch tipo.uppercased() {
        case "ENTRADA":
            return "Fichaje de Entrada realizado correctamente"
        case "SALIDA":
            return "Fichaje de Salida realizado correctamente"
        case "PROBLEMA GPS":
            return "No se detecta la geolocalización gps. Por favor, active la geolocalización gps para poder fichar y vuelvalo a intentar en unos segundos."
        case "PROBLEMA INTERNET":
            return "El dispositivo no está conectado a la red. Revise su conexión a Internet."
        case "POSIBLE UBI FALSA":
            return "Se detectó una posible ubicación falsa. Reinicie su geolocalización gps y vuelva a intentarlo en unos minutos"
        case "VPN DETECTADA":
            return "VPN detectada. Desactive la VPN para continuar y vuelva a intentarlo en unos minutos."
        default:
            return "Fichaje de \(tipo) realizado correctamente"
        }
    }

    private var colorFondo: Color {
        switch tipo.uppercased() {
        case "ENTRADA":
            return Color(red: 0.07, green: 0.27, blue: 0.45)
        case "SALIDA":
            return Color(red: 0.84, green: 0.92, blue: 0.98)
        default:
            return Color.red
        }
    }

    private var colorTextoEncabezado: Color {
        return tipo.uppercased() == "SALIDA" ? Color(red: 0.07, green: 0.27, blue: 0.45) : .white
    }

    private var textoEncabezado: String {
        switch tipo.uppercased() {
        case "ENTRADA":
            return "ENTRADA"
        case "SALIDA":
            return "SALIDA"
        default:
            return "ERROR DE FICHAJE"
        }
    }

    private var fechaHora: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "dd/MM/yyyy HH:mm'h'"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    Text(textoEncabezado)
                        .foregroundColor(colorTextoEncabezado)
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(colorFondo)

                    VStack(spacing: 16) {
                        Text(mensaje)
                            .foregroundColor(.black)
                            .font(.system(size: 18))
                            .multilineTextAlignment(.center)

                        Text(fechaHora)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        Button(action: onClose) {
                            Text("Cerrar")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 8)
                                .background(colorFondo)
                                .foregroundColor(colorTextoEncabezado)
                                .cornerRadius(6)
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: Funcion que se encarga de mostrar los horarios del usuario logeado
import Combine
struct BotonesFichajeView: View {
    let webView: WKWebView?
    let onFichaje: (String) -> Void
    let onShowAlert: (String) -> Void
    @State private var ultimoFichajeTimestamp: TimeInterval = 0
    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""

    var body: some View {
        ZStack {
            VStack {
                BotonFichaje(tipo: "ENTRADA")
                // Espacio vertical entre los dos botones
                Spacer().frame(height: 40)
                BotonFichaje(tipo: "SALIDA")
            }

            if mostrarAlerta {
                MensajeAlerta(tipo: mensajeAlerta) {
                    withAnimation {
                        mostrarAlerta = false
                    }
                }
                .transition(.asymmetric(insertion: .scale(scale: 0.9).combined(with: .opacity),
                                        removal: .opacity))
                .zIndex(10)
            }
        }
    }

    @ViewBuilder
    private func BotonFichaje(tipo: String) -> some View {
        Button(action: {
            Task {
                guard !SeguridadUtils.shared.isUsingVPN() else {
                    print("🚫 VPN detectada")
                    withAnimation {
                        mensajeAlerta = "VPN DETECTADA"
                        mostrarAlerta = true
                    }
                    return
                }

                guard SeguridadUtils.shared.isInternetAvailable() else {
                    print("📡 Sin conexión")
                    withAnimation {
                        mensajeAlerta = "PROBLEMA INTERNET"
                        mostrarAlerta = true
                    }
                    return
                }

                guard SeguridadUtils.shared.hasLocationPermission() else {
                    print("📍 Sin permiso de localización")
                    withAnimation {
                        mensajeAlerta = "PROBLEMA GPS"
                        mostrarAlerta = true
                    }
                    return
                }

                SeguridadUtils.shared.detectarUbicacionReal { resultado in
                    switch resultado {
                    case .gpsDesactivado:
                        print("📍 GPS desactivado")
                        withAnimation {
                            mensajeAlerta = "PROBLEMA GPS"
                            mostrarAlerta = true
                        }
                        return
                    case .ubicacionSimulada:
                        print("🛰️ Ubicación simulada detectada")
                        withAnimation {
                            mensajeAlerta = "POSIBLE UBI FALSA"
                            mostrarAlerta = true
                        }
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
                        withAnimation {
                            mensajeAlerta = "Fichaje de tipo \(tipo) realizado correctamente"
                            mostrarAlerta = true
                        }
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


// MARK: Nos muestras los fichajes que ha hecho la persona en la fecha actual o la que seleccione el usuario
struct FichajeVisual {
    let entrada: String
    let salida: String
    let lcumEnt: String
    let lcumSal: String
}

struct RecuadroFichajesDia: View {
    @Binding var refreshTrigger: Int
    @State private var fechaSeleccionada: Date = Date()
    @State private var fichajes: [FichajeVisual] = []
    @State private var mostrarCalendario = false
    @State private var fechaTemporal = Date()

    var body: some View {
        VStack(spacing: 10) {
            Text("Fichajes Día")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71))
                .offset(y: -20)

            HStack(spacing: 10) {
                // Botón de calendario
                Button {
                    fechaTemporal = fechaSeleccionada
                    mostrarCalendario = true
                } label: {
                    Image("ic_calendario")
                        .resizable()
                        .frame(width: 26, height: 26)
                }
                .sheet(isPresented: $mostrarCalendario) {
                    VStack(spacing: 20) {
                        DatePicker(
                            "Selecciona una fecha",
                            selection: $fechaTemporal,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        Button("Aceptar") {
                            fechaSeleccionada = fechaTemporal
                            mostrarCalendario = false
                        }
                        .font(.headline)
                        .padding()
                    }
                    .padding()
                }
                Button {
                    if let fecha = Calendar.current.date(byAdding: .day, value: -1, to: fechaSeleccionada) {
                        fechaSeleccionada = fecha
                    }
                } label: {
                    Image("hacia_atras").resizable().frame(width: 26, height: 26)
                }
                Text(formattedVisibleDate)
                    .font(.system(size: 22))
                    .foregroundColor(.gray)
                Button {
                    if let fecha = Calendar.current.date(byAdding: .day, value: 1, to: fechaSeleccionada) {
                        fechaSeleccionada = fecha
                    }
                } label: {
                    Image("hacia_delante").resizable().frame(width: 26, height: 26)
                }
                Button {
                    Task {
                        do {
                            let fecha = try await ManejoDeSesion.shared.obtenerFechaHoraInternetAsync()
                            fechaSeleccionada = fecha
                        } catch {
                            print("❌ Error al obtener la fecha desde el servidor: \(error)")
                        }
                    }
                } label: {
                    Image("reload").resizable().frame(width: 32, height: 32)
                }
            }

            VStack(spacing: 10) {
                if fichajes.isEmpty {
                    Text("No hay fichajes hoy")
                        .font(.system(size: 23))
                        .foregroundColor(.gray)
                } else {
                    ForEach(fichajes.indices, id: \.self) { i in
                        let f = fichajes[i]
                        HStack {
                            Text("\(f.entrada) - ")
                                .font(.system(size: 23))
                                .foregroundColor(color(for: f.lcumEnt))
                            Text(f.salida)
                                .font(.system(size: 23))
                                .foregroundColor(color(for: f.lcumSal))
                        }
                    }
                }
            }
            .padding(10)
            .background(Color.white)
        }
        .onChange(of: fechaSeleccionada, fetchFichajes)
        .onChange(of: refreshTrigger, fetchFichajes)
        .task { fetchFichajes() }
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: fechaSeleccionada)
    }

    var formattedVisibleDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "dd/MM/yyyy"
        return f.string(from: fechaSeleccionada)
    }

    func color(for valor: String) -> Color {
        switch valor {
        case "true": return .green
        case "false": return .red
        default: return Color(red: 0.46, green: 0.60, blue: 0.71)
        }
    }

    func fetchFichajes() {
        guard AuthManager.shared.getUserCredentials().xEmpleado.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) != nil else { return }
        let urlString = BuildURLMovil.getURLFichajesDia() + "&fecha=\(formattedDate)"
        print("📡 URL consultada para fichajes del día: \(urlString)")
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let raw = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\u{feff}", with: ""),
                  let json = try? JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any],
                  let arr = json["dataFichajes"] as? [[String: Any]] else {
                DispatchQueue.main.async { self.fichajes = [] }
                return
            }

            let nuevos = arr.compactMap { item -> FichajeVisual? in
                let entradaMinutos = item["nMinEnt"]
                let salidaMinutos = item["nMinSal"]

                print("🔍 Datos crudos recibidos: nMinEnt=\(String(describing: entradaMinutos)), nMinSal=\(String(describing: salidaMinutos))")

                func convertirMinutosAHoraTexto(_ valor: Any?) -> String {
                    if let str = valor as? String, let minutos = Int(str) {
                        let horas = minutos / 60
                        let mins = minutos % 60
                        return String(format: "%02d:%02d h", horas, mins)
                    } else if let minutos = valor as? Int {
                        let horas = minutos / 60
                        let mins = minutos % 60
                        return String(format: "%02d:%02d h", horas, mins)
                    } else {
                        return "??"
                    }
                }

                let entrada = convertirMinutosAHoraTexto(entradaMinutos)
                let salida = convertirMinutosAHoraTexto(salidaMinutos)

                print("🕒 Horas formateadas: entrada=\(entrada), salida=\(salida)")

                return FichajeVisual(
                    entrada: entrada,
                    salida: salida,
                    lcumEnt: (item["lCumEnt"] as? Bool)?.description ?? "",
                    lcumSal: (item["lCumSal"] as? Bool)?.description ?? ""
                )
            }

            DispatchQueue.main.async {
                self.fichajes = nuevos
            }
        }.resume()
    }
}

// Helper para sumar días a Date
fileprivate extension Date {
    mutating func addDays(_ days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: self) {
            self = newDate
        }
    }
}


// MARK: Esta función se encarga de mostrar las Alertas que pueda tener el usuario
struct AvisoItem: Identifiable {
    let id = UUID()
    let titulo: String
    let detalle: String
    let url: String?
}

struct AlertasDiariasView: View {
    let onAbrirWebView: (String) -> Void
    let hideCuadroParaFichar: () -> Void
    @Binding var refreshTrigger: Int

    @State private var avisos: [AvisoItem] = []
    @State private var expandedStates: [UUID: Bool] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Avisos / Alertas")
                .font(.system(size: 23, weight: .bold))
                .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71))
                .padding(.horizontal, 8)

            if avisos.isEmpty {
                Text("Cargando alertas...")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            } else {
                ForEach(avisos) { aviso in
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: expandedStates[aviso.id] == true ? "minus.circle" : "plus.circle")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71))
                                .onTapGesture {
                                    expandedStates[aviso.id] = !(expandedStates[aviso.id] ?? false)
                                }

                            Text(aviso.titulo)
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71))
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer()

                            if let url = aviso.url, !url.isEmpty {
                                Image(systemName: "arrow.right.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71))
                                    .onTapGesture {
                                        onAbrirWebView(url)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            hideCuadroParaFichar()
                                        }
                                    }
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3)))

                        if expandedStates[aviso.id] == true {
                            Text(aviso.detalle)
                                .font(.system(size: 16))
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .onAppear {
            fetchAlertas()
            // refresco automático cada 10 minutos
            Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { _ in
                refreshTrigger += 1
                fetchAlertas()
            }
        }
        .onChange(of: refreshTrigger) {
            fetchAlertas()
        }
    }

    func fetchAlertas() {
        print("📡 URL_Alertas invocada: \(BuildURLMovil.getURLAlertas())")
        guard let url = URL(string: BuildURLMovil.getURLAlertas()) else { return }

        var request = URLRequest(url: url)
        if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
            let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            request.addValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let jsonString = String(data: data, encoding: .utf8)?
                      .replacingOccurrences(of: "\u{feff}", with: ""),
                  let json = try? JSONSerialization.jsonObject(with: Data(jsonString.utf8)) as? [String: Any],
                  let arr = json["dataAvisos"] as? [[String: Any]]
            else {
                DispatchQueue.main.async {
                    self.avisos = [AvisoItem(titulo: "No hay alertas disponibles", detalle: "", url: nil)]
                }
                return
            }

            let nuevos = arr.map {
                AvisoItem(
                    titulo: $0["D_AVISO"] as? String ?? "Sin aviso",
                    detalle: $0["T_AVISO"] as? String ?? "",
                    url: ($0["T_URL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

            DispatchQueue.main.async {
                self.avisos = nuevos.isEmpty
                    ? [AvisoItem(titulo: "No hay alertas disponibles", detalle: "", url: nil)]
                    : nuevos
            }
        }.resume()
    }
}


