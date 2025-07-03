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
                    if let logoCliente = ImagenesMovil.logoCliente {
                        logoCliente
                            .resizable()
                            .scaledToFit()
                            .frame(width: 260, height: 130)
                            .padding(.top, -30)
                    }



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
