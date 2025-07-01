//
//  PaginaSecundariaView.swift
//  Kairos24h
//
//  Created by Juan López on 2025.
//

import SwiftUI
import WebKit

// Esta vista muestra una pantalla secundaria con un WebView que carga una URL protegida
// Realiza login automático mediante JavaScript y gestiona el cierre de sesión por inactividad
struct PaginaSecundariaView: View {
    // Tiempo máximo de sesión (2 horas)
    private let sessionTimeout: TimeInterval = 2 * 60 * 60
    @State private var timer: Timer?
    @State private var webViewReloadTrigger = UUID()
    @Binding var mostrarLogin: Bool
    @State private var mostrandoReconectando = false
    @State private var mostrarSolapa = true
    @State private var webViewReferencia = WKWebView()
    @State private var showLogoutDialog = false
    @State private var navegar = false
    @State private var xEmpleado: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    Color(red: 0xE2 / 255.0, green: 0xE4 / 255.0, blue: 0xE5 / 255.0)

                    HStack {
                        // Sección izquierda: avatar + nombre
                        HStack(spacing: 8) {
                            Image("cliente32")
                                .resizable()
                                .frame(width: 24, height: 24)

                            Text((AuthManager.shared.getUserCredentials().usuario ?? "").uppercased())
                                .foregroundColor(Color(red: 0.46, green: 0.60, blue: 0.71)) // Color(0xFF7599B6)
                                .font(.system(size: 14, weight: .medium))
                        }

                        Spacer()

                        // Sección derecha: botón cerrar sesión
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

                WebViewWrapper(
                    reloadTrigger: webViewReloadTrigger,
                    mostrarLogin: $mostrarLogin,
                    mostrandoReconectando: $mostrandoReconectando,
                    webView: $webViewReferencia
                )
                .frame(maxHeight: .infinity)
                .padding(.bottom, 56)
            }
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
            .zIndex(0)
            .background(Color.white)
            .overlay(
                Group {
                    if mostrarSolapa {
                        SolapaWebView(
                            webView: webViewReferencia,
                            onClose: { mostrarSolapa = false },
                            mostrarLogin: $mostrarLogin
                        )
                        .zIndex(2)
                    }

                    VStack {
                        Spacer()
                        Button(action: {
                            mostrarSolapa = true
                        }) {
                            Image("menu_opciones")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .padding()
                        }
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding(.bottom, 20)
                    }
                    .zIndex(1)
                }
            )
            .onAppear {
                print("✅ PaginaSecundariaView - onAppear ejecutado")
                xEmpleado = AuthManager.shared.getUserCredentials().xEmpleado ?? ""
                print("🧾 xEmpleado recuperado: \(xEmpleado)")
                iniciarTimerDeSesion()
            }
            .onDisappear {
                timer?.invalidate()
                print("🔄 PaginaSecundariaView - onDisappear: temporizador detenido")
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $navegar) {
                PaginaPrincipalViewController()
            }
        }
    }

    // Inicia un temporizador que cierra la sesión tras el tiempo definido
    private func iniciarTimerDeSesion() {
        print("⏱️ Iniciando temporizador de sesión")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { _ in
            print("⚠️ Tiempo de sesión agotado, cerrando sesión")
            cerrarSesion()
        }
    }

    // Cierra la sesión y limpia todos los datos de navegación
    private func cerrarSesion() {
        print("🚪 Cerrando sesión y limpiando datos web")
        AuthManager.shared.clearAllUserData()
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                dataStore.removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }

        // Aquí podrías disparar una navegación a la vista de login usando un Binding o NavigationLink
    }
}

// Representa un WKWebView en SwiftUI
struct WebViewWrapper: UIViewRepresentable {
    let reloadTrigger: UUID
    @Binding var mostrarLogin: Bool
    @Binding var mostrandoReconectando: Bool
    @Binding var webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        print("⚙️ Configurando WKWebView")
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "loginStatus")
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        cargarURLPrincipal(en: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Puedes usar reloadTrigger para forzar recarga
    }

    private func cargarURLPrincipal(en webView: WKWebView) {
        print("🌐 Intentando cargar la URL principal")
        let urlString = BuildURLMovil.getIndex()
        if let url = URL(string: urlString) {
            print("🔗 URL válida: \(urlString)")
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            print("❌ URL inválida")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(mostrarLogin: $mostrarLogin, mostrandoReconectando: $mostrandoReconectando)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var mostrarLogin: Binding<Bool>
        var mostrandoReconectando: Binding<Bool>

        init(mostrarLogin: Binding<Bool>, mostrandoReconectando: Binding<Bool>) {
            self.mostrarLogin = mostrarLogin
            self.mostrandoReconectando = mostrandoReconectando
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView terminó de cargar")
            let creds = AuthManager.shared.getUserCredentials()
            let rawUsuario: String? = creds.usuario
            let rawPassword: String? = creds.password

            // Verifica que las credenciales sean válidas y decodifica
            guard let usuario = rawUsuario?.removingPercentEncoding,
                  let password = rawPassword?.removingPercentEncoding else {
                print("❌ Credenciales no válidas, cerrando sesión")
                return
            }

            // Muestra overlay de reconectando antes de inyectar JS
            mostrandoReconectando.wrappedValue = true

            print("💻 Inyectando JavaScript para login automático")
            let jsScript = """
            (function() {
                isMobile = () => true;
                document.getElementsByName('LoginForm[username]')[0].value = '\(usuario)';
                document.getElementsByName('LoginForm[password]')[0].value = '\(password)';
                document.querySelector('form').submit();
                setTimeout(function() {
                    var panels = document.querySelectorAll('.panel, .panel-body, .panel-heading');
                    panels.forEach(function(panel) {
                        panel.style.display = 'block';
                        panel.style.visibility = 'visible';
                        panel.style.opacity = '1';
                        panel.style.maxHeight = 'none';
                    });
                    document.body.style.overflow = 'auto';
                    document.documentElement.style.overflow = 'auto';
                    window.webkit.messageHandlers.loginStatus.postMessage('success');
                }, 3000);
            })();
            """

            webView.evaluateJavaScript(jsScript) { result, error in
                if let error = error {
                    print("❌ Error ejecutando JS: \(error.localizedDescription)")
                } else {
                    print("✅ JS ejecutado correctamente")
                }
            }

            let checkLoginJS = """
            setTimeout(function() {
                if (document.querySelector('form') !== null) {
                    window.webkit.messageHandlers.loginStatus.postMessage('failed');
                }
            }, 4000);
            """
            webView.evaluateJavaScript(checkLoginJS, completionHandler: nil)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "loginStatus" {
                if let result = message.body as? String {
                    if result == "failed" {
                        print("❌ Login automático fallido. Redirigiendo al login.")
                        AuthManager.shared.clearAllUserData()
                        mostrarLogin.wrappedValue = true
                        mostrandoReconectando.wrappedValue = false
                    } else if result == "success" {
                        print("✅ Login automático exitoso. Ocultando overlay.")
                        mostrandoReconectando.wrappedValue = false
                    }
                }
            }
        }
    }
}
