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

            HStack {
                HStack(spacing: 8) {
                    Image("cliente32")
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
        }
        .navigationDestination(isPresented: $navegar) {
            PaginaPrincipalViewController()
        }
    }

    private func columnaIconos(_ iconos: [(String, String, String)]) -> some View {
        VStack(spacing: 28) {
            ForEach(iconos, id: \.0) { item in
                botonNavegador(label: item.0, imageName: item.1, urlString: item.2)
            }
        }
    }

    private func botonNavegador(label: String, imageName: String, urlString: String) -> some View {
        Button(action: {
            if let url = URL(string: urlString) {
                webView.load(URLRequest(url: url))
                onClose()
            }
        }) {
            VStack(spacing: 8) {
                Image(imageName)
                    .resizable()
                    .frame(width: 86, height: 86)
                Text(label)
                    .font(.system(size: 17, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 6/255, green: 82/255, blue: 161/255))
                    .frame(width: 96, height: 66)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: false)
            }
            .frame(width: 100, height: 130)
        }
    }
}
