import SwiftUI
import Reachability

struct PaginaPrincipalViewController: View {
    @State private var usuario: String = ""
    @State private var password: String = ""
    @State private var mostrarContrasena: Bool = false
    @State private var errorTexto: String = ""
    @State private var navegar: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo del cliente
                    if let logo = ImagenesMovil.logoCliente {
                        logo
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    }

                    // Campo de usuario
                    TextField("Usuario", text: $usuario)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)

                    // Campo de contraseña
                    if mostrarContrasena {
                        TextField("Contraseña", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        SecureField("Contraseña", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // Mostrar contraseña con switch
                    Toggle("Mostrar contraseña", isOn: $mostrarContrasena)

                    // Etiqueta para mostrar errores
                    if !errorTexto.isEmpty {
                        Text(errorTexto)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }

                    // Botón de acceso
                    Button(action: handleLogin) {
                        Text("Acceso")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 117/255, green: 153/255, blue: 182/255))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }

                    // Botón de "¿Olvidaste la contraseña?"
                    Button(action: handleForgotPassword) {
                        Text("¿Olvidaste la contraseña?")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 117/255, green: 153/255, blue: 182/255))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 40)
            }
            .navigationBarHidden(true)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                let creds = AuthManager.shared.getUserCredentials()
                if !creds.usuario.isEmpty && !creds.password.isEmpty {
                    print("➡️ Autologin detectado, navegando a pantalla secundaria")
                    navegar = true
                }
            }
            .navigationDestination(isPresented: $navegar) {
                PaginaSecundariaView(mostrarLogin: .constant(false))
            }
        }
    }

    // Maneja el proceso de login tras pulsar "Acceso"
    func handleLogin() {
        let trimmedUsuario = usuario.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)

        guard !trimmedUsuario.isEmpty && !trimmedPassword.isEmpty else {
            errorTexto = "Por favor, completa ambos campos"
            return
        }

        if !isInternetAvailable() {
            errorTexto = "Compruebe su conexión a Internet"
            return
        }

        errorTexto = ""

        AuthManager.shared.authenticateUser(usuario: trimmedUsuario, password: trimmedPassword) { success, xEmpleado in
            DispatchQueue.main.async {
                if success, let xEmpleado = xEmpleado {
                    AuthManager.shared.saveUserCredentials(
                        usuario: xEmpleado.usuario,
                        password: xEmpleado.password,
                        xEmpleado: xEmpleado.xEmpleado,
                        lComGPS: xEmpleado.lComGPS,
                        lComIP: xEmpleado.lComIP,
                        lBotonesFichajeMovil: xEmpleado.lBotonesFichajeMovil,
                        xEntidad: xEmpleado.xEntidad,
                        sEmpleado: xEmpleado.sEmpleado,
                        tUrlCPP: xEmpleado.tUrlCPP,
                        tLogo: xEmpleado.tLogo,
                        cTipEmp: xEmpleado.cTipEmp
                    )
                    print("✅ Credenciales guardadas:")
                    print("usuario: \(xEmpleado.usuario)")
                    print("password: \(xEmpleado.password)")
                    print("xEmpleado: \(xEmpleado.xEmpleado)")
                    print("lComGPS: \(xEmpleado.lComGPS)")
                    print("lComIP: \(xEmpleado.lComIP)")
                    print("lBotonesFichajeMovil: \(xEmpleado.lBotonesFichajeMovil)")
                    print("xEntidad: \(xEmpleado.xEntidad)")
                    print("sEmpleado: \(xEmpleado.sEmpleado)")
                    print("tUrlCPP: \(xEmpleado.tUrlCPP)")
                    print("tLogo: \(xEmpleado.tLogo)")
                    print("cTipEmp: \(xEmpleado.cTipEmp)")
                    navegar = true
                } else {
                    errorTexto = "Usuario o contraseña incorrectos"
                }
            }
        }
    }

    // Redirige al usuario a la pantalla de recuperación de contraseña
    func handleForgotPassword() {
        if let url = URL(string: BuildURLMovil.getForgotPassword()) {
            UIApplication.shared.open(url)
        }
    }

    // Verifica si hay conexión a Internet disponible
    func isInternetAvailable() -> Bool {
        guard let reachability = try? Reachability() else {
            return false
        }
        return reachability.connection != .unavailable
    }
}
