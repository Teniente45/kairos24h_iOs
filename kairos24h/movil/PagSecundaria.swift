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
        // NavigationStack para gestionar la navegación dentro de la app
        NavigationStack {
            VStack(spacing: 0) {
                // Cabecera con información del usuario y opción de logout
                CabeceraUsuarioView(showLogoutDialog: $showLogoutDialog, navegar: $navegar)

                // Contenedor del WebView que carga la URL protegida
                WebViewWrapper(
                    reloadTrigger: webViewReloadTrigger,
                    mostrarLogin: $mostrarLogin,
                    mostrandoReconectando: $mostrandoReconectando,
                    webView: $webViewReferencia
                )
                .frame(maxHeight: UIScreen.main.bounds.height * 0.85)

                // Barra de navegación inferior para controlar el WebView y mostrar/ocultar solapa
                BarraNavBottom(webView: webViewReferencia, mostrarSolapa: $mostrarSolapa)
            }
            // Alerta para confirmar cierre de sesión
            .alert(isPresented: $showLogoutDialog) {
                Alert(
                    title: Text("¿Quieres cerrar la sesión?"),
                    primaryButton: .destructive(Text("Sí")) {
                        // Limpia datos y navega a pantalla principal
                        AuthManager.shared.clearAllUserData()
                        navegar = true
                    },
                    secondaryButton: .cancel(Text("No"))
                )
            }
            .zIndex(0)
            // Overlay que muestra una solapa con contenido adicional sobre el WebView
            .overlay(
                Group {
                    if mostrarSolapa {
                        SolapaWebView(
                            webView: webViewReferencia,
                            onClose: { mostrarSolapa = false },
                            mostrarLogin: $mostrarLogin,
                            mostrarSolapa: $mostrarSolapa
                        )
                        .zIndex(2) // Asegura que la solapa esté por encima del resto
                    }
                }
            )
            // Acciones al aparecer la vista
            .onAppear {
                print("✅ PaginaSecundariaView - onAppear ejecutado")
                xEmpleado = AuthManager.shared.getUserCredentials().xEmpleado
                print("🧾 xEmpleado recuperado: \(xEmpleado)")
                iniciarTimerDeSesion()
            }
            // Acciones al desaparecer la vista
            .onDisappear {
                timer?.invalidate()
                print("🔄 PaginaSecundariaView - onDisappear: temporizador detenido")
            }
            .navigationBarBackButtonHidden(true) // Oculta el botón de volver predeterminado
            // Navegación programática a PaginaPrincipalViewController cuando navegar es true
            .navigationDestination(isPresented: $navegar) {
                PaginaPrincipalViewController()
            }
        }
    }

    // MARK: - Funciones de gestión de sesión
    /// Inicia un temporizador que cierra la sesión tras el tiempo definido para evitar inactividad prolongada
    private func iniciarTimerDeSesion() {
        print("⏱️ Iniciando temporizador de sesión")
        timer?.invalidate() // Si ya hay un temporizador activo, lo invalida
        timer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { _ in
            print("⚠️ Tiempo de sesión agotado, cerrando sesión")
            cerrarSesion()
        }
    }

    /// Cierra la sesión y limpia todos los datos de navegación almacenados en el WebView
    private func cerrarSesion() {
        print("🚪 Cerrando sesión y limpiando datos web")
        AuthManager.shared.clearAllUserData()
        let dataStore = WKWebsiteDataStore.default()
        // Elimina todos los datos almacenados (cookies, cache, etc.)
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                dataStore.removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }

        // Aquí podrías disparar una navegación a la vista de login usando un Binding o NavigationLink
    }
}

// Representa un WKWebView en SwiftUI y gestiona la carga de la URL y el login automático
struct WebViewWrapper: UIViewRepresentable {
    let reloadTrigger: UUID
    @Binding var mostrarLogin: Bool
    @Binding var mostrandoReconectando: Bool
    @Binding var webView: WKWebView

    /// Crea y configura el WKWebView con JavaScript habilitado y el controlador de mensajes
    func makeUIView(context: Context) -> WKWebView {
        print("⚙️ Configurando WKWebView")
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true // Permite ejecutar JS
        config.defaultWebpagePreferences = preferences
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Añade el controlador para recibir mensajes JS desde la página
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "loginStatus")
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        cargarURLPrincipal(en: webView)
        return webView
    }

    /// Actualiza la vista; aquí podrías usar reloadTrigger para forzar recarga si se modifica
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Puedes usar reloadTrigger para forzar recarga
    }

    /// Carga la URL principal que se quiere mostrar en el WebView
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

    /// Crea el coordinador que actúa como delegado para WKWebView y maneja mensajes JS
    func makeCoordinator() -> Coordinator {
        Coordinator(mostrarLogin: $mostrarLogin, mostrandoReconectando: $mostrandoReconectando)
    }

    // MARK: - Coordinador para manejar navegación y comunicación JS
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var mostrarLogin: Binding<Bool>
        var mostrandoReconectando: Binding<Bool>

        init(mostrarLogin: Binding<Bool>, mostrandoReconectando: Binding<Bool>) {
            self.mostrarLogin = mostrarLogin
            self.mostrandoReconectando = mostrandoReconectando
        }

        /// Se llama cuando el WebView termina de cargar una página
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
            // Script JS que realiza el login automático en la página cargada
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

            // Ejecuta el JS en el WebView
            webView.evaluateJavaScript(jsScript) { result, error in
                if let error = error {
                    print("❌ Error ejecutando JS: \(error.localizedDescription)")
                } else {
                    print("✅ JS ejecutado correctamente")
                }
            }

            // Script que verifica si el login falló (el formulario sigue visible)
            let checkLoginJS = """
            setTimeout(function() {
                if (document.querySelector('form') !== null) {
                    window.webkit.messageHandlers.loginStatus.postMessage('failed');
                }
            }, 4000);
            """
            webView.evaluateJavaScript(checkLoginJS, completionHandler: nil)
        }

        /// Maneja los mensajes enviados desde el JavaScript en la página web
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
