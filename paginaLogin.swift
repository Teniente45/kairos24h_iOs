import UIKit
import CoreLocation

class LoginViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var isLocationGranted = false

    let usernameField = UITextField()
    let passwordField = UITextField()
    let loginButton = UIButton(type: .system)
    let forgotPasswordButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupTextFields()
        setupButtons()
        setupConstraints()

        // Verificar si hay credenciales almacenadas
        if let storedUser = UserDefaults.standard.string(forKey: "usuario"),
           let storedPassword = UserDefaults.standard.string(forKey: "password"),
           let cTipEmp = UserDefaults.standard.string(forKey: "cTipEmp")?.uppercased(),
           !storedUser.isEmpty, !storedPassword.isEmpty {

            if cTipEmp == "TABLET" {
                navigateToTabletMain() // Se puede eliminar si ya no se usará tablet
            } else {
                navigateToFichar(usuario: storedUser, password: storedPassword)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - UI Setup

    func setupTextFields() {
        usernameField.placeholder = "Usuario"
        usernameField.borderStyle = .roundedRect
        view.addSubview(usernameField)

        passwordField.placeholder = "Contraseña"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .roundedRect
        view.addSubview(passwordField)
    }

    func setupButtons() {
        loginButton.setTitle("Acceso", for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.46, green: 0.60, blue: 0.71, alpha: 1.0)
        loginButton.tintColor = .white
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        view.addSubview(loginButton)

        forgotPasswordButton.setTitle("¿Olvidaste la contraseña?", for: .normal)
        forgotPasswordButton.addTarget(self, action: #selector(openForgotPassword), for: .touchUpInside)
        view.addSubview(forgotPasswordButton)
    }

    func setupConstraints() {
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            usernameField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            usernameField.widthAnchor.constraint(equalToConstant: 250),

            passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 20),
            passwordField.widthAnchor.constraint(equalTo: usernameField.widthAnchor),

            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 30),
            loginButton.widthAnchor.constraint(equalTo: usernameField.widthAnchor),
            loginButton.heightAnchor.constraint(equalToConstant: 44),

            forgotPasswordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            forgotPasswordButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 10)
        ])
    }

    // MARK: - Lógica de autenticación

    @objc func handleLogin() {
        guard let username = usernameField.text, let password = passwordField.text,
              !username.isEmpty, !password.isEmpty, isLocationGranted else {
            showAlert("Rellene los campos y permita ubicación")
            return
        }

        authenticateUser(usuario: username, password: password)
    }

    func authenticateUser(usuario: String, password: String) {
        let isValid = (usuario == "demo" && password == "1234")
        let xEmpleado = "123"
        let cTipEmp = "APK" // TODO: eliminar lógica de TABLET si no se usa

        if isValid {
            UserDefaults.standard.set(usuario, forKey: "usuario")
            UserDefaults.standard.set(password, forKey: "password")
            UserDefaults.standard.set(xEmpleado, forKey: "xEmpleado")
            UserDefaults.standard.set(cTipEmp, forKey: "cTipEmp")

            if cTipEmp.uppercased() == "TABLET" {
                navigateToTabletMain()
            } else {
                navigateToFichar(usuario: usuario, password: password)
            }
        } else {
            showAlert("Usuario o contraseña incorrectos")
        }
    }

    func navigateToFichar(usuario: String, password: String) {
        let ficharVC = FicharViewController()
        ficharVC.usuario = usuario
        ficharVC.password = password
        navigationController?.pushViewController(ficharVC, animated: true)
    }

    func navigateToTabletMain() {
        let tabletVC = TabletMainViewController()
        navigationController?.pushViewController(tabletVC, animated: true)
    }

    @objc func openForgotPassword() {
        if let url = URL(string: "https://kairos24h.es/forgot-password") {
            UIApplication.shared.open(url)
        }
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Atención", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
        present(alert, animated: true)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        isLocationGranted = CLLocationManager.locationServicesEnabled() &&
            (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
}
