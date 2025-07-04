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
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 130)
                            .padding(.top, -30)
                    } else if let logoCliente = ImagenesMovil.logoCliente {
                        logoCliente
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 130)
                            .padding(.top, -30)
                    }

                    MiHorarioView()

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
        .padding(.bottom, 20)
        .padding(.top, -10)
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
