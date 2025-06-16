//
//  Fichar.swift
//  kairos24h
//
//  Created by Juan López Marín on 13/6/25.
//


import UIKit
import WebKit
import CoreLocation

// MARK: - FicharViewController
class FicharViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, CLLocationManagerDelegate {
    private var webView: WKWebView!
    private var sessionTimer: Timer?
    private let sessionTimeout: TimeInterval = 2 * 60 * 60 // 2 horas
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var overlayView: UIView!
    private var loadingView: UIView!
    private var ficharPanel: FicharPanelView?
    private var isLoading = false
    private var showFicharPanel = false
    private var navigationBar: FicharNavigationBar!
    private var bottomBar: FicharBottomBar!
    private var storedUser: String = ""
    private var storedPassword: String = ""
    private var lComGPS: String = "S"
    private var lComIP: String = "S"
    private var lBotonesFichajeMovil: String = ""
    private var fichajeAlertTipo: String?

    // Setter público para credenciales
    func setCredenciales(usuario: String, password: String) {
        self.storedUser = usuario
        self.storedPassword = password
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        loadCredentials()
        guard !storedUser.isEmpty, !storedPassword.isEmpty else {
            navigateToLogin()
            return
        }
        setupWebView()
        setupNavigationBar()
        setupBottomBar()
        setupOverlayView()
        startSessionTimer()
        // Auto-login after webView loaded
        webView.navigationDelegate = self
        webView.uiDelegate = self
        let urlStr = BuildURLmovil.getIndex()
        if let url = URL(string: urlStr) {
            webView.load(URLRequest(url: url))
        }
    }

    private func loadCredentials() {
        let defaults = UserDefaults.standard
        storedUser = defaults.string(forKey: "usuario") ?? ""
        storedPassword = defaults.string(forKey: "password") ?? ""
        lComGPS = defaults.string(forKey: "lComGPS") ?? "S"
        lComIP = defaults.string(forKey: "lComIP") ?? "S"
        lBotonesFichajeMovil = defaults.string(forKey: "lBotonesFichajeMovil") ?? ""
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = true
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -56),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupNavigationBar() {
        navigationBar = FicharNavigationBar(username: storedUser)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.logoutHandler = { [weak self] in
            self?.showLogoutDialog()
        }
        view.addSubview(navigationBar)
        NSLayoutConstraint.activate([
            navigationBar.topAnchor.constraint(equalTo: view.topAnchor),
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setupBottomBar() {
        bottomBar = FicharBottomBar()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.delegate = self
        view.addSubview(bottomBar)
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func setupOverlayView() {
        overlayView = UIView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = UIColor.clear
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        overlayView.isUserInteractionEnabled = false
    }

    private func showLoading(_ show: Bool) {
        if show {
            if loadingView == nil {
                loadingView = UIView(frame: overlayView.bounds)
                loadingView.backgroundColor = .white
                loadingView.alpha = 0.9
                let spinner = UIActivityIndicatorView(style: .large)
                spinner.center = loadingView.center
                spinner.startAnimating()
                loadingView.addSubview(spinner)
            }
            overlayView.addSubview(loadingView)
        } else {
            loadingView?.removeFromSuperview()
        }
    }

    private func showFicharPanelView(_ show: Bool) {
        showFicharPanel = show
        if show {
            if ficharPanel == nil {
                ficharPanel = FicharPanelView()
                ficharPanel?.delegate = self
                ficharPanel?.translatesAutoresizingMaskIntoConstraints = false
                overlayView.addSubview(ficharPanel!)
                NSLayoutConstraint.activate([
                    ficharPanel!.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
                    ficharPanel!.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
                    ficharPanel!.widthAnchor.constraint(equalTo: overlayView.widthAnchor, multiplier: 0.8),
                    ficharPanel!.heightAnchor.constraint(equalToConstant: 220)
                ])
            }
            ficharPanel?.isHidden = false
        } else {
            ficharPanel?.isHidden = true
        }
    }

    private func showLogoutDialog() {
        let alert = UIAlertController(title: "¿Cerrar sesión?", message: "Si continuas cerrarás tu sesión, ¿Seguro que es lo que quieres hacer?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sí", style: .destructive, handler: { [weak self] _ in
            self?.clearSessionAndLogout()
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    private func clearSessionAndLogout() {
        // Remove cookies
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) { }
        }
        // Remove user defaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "usuario")
        defaults.removeObject(forKey: "password")
        defaults.removeObject(forKey: "lComGPS")
        defaults.removeObject(forKey: "lComIP")
        defaults.removeObject(forKey: "lBotonesFichajeMovil")
        defaults.synchronize()
        navigateToLogin()
    }

    private func navigateToLogin() {
        // Implement navigation to login screen (replace rootViewController)
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = MainViewController()
                window.makeKeyAndVisible()
            }
        }
    }

    // MARK: - Session Timer
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            self?.clearSessionAndLogout()
        }
    }
    private func resetSessionTimer() {
        startSessionTimer()
    }

    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Auto-login after page loads
        let user = storedUser.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let pass = storedPassword.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let js =
        """
        (function() {
            isMobile = () => true;
            document.getElementsByName('LoginForm[username]')[0].value = '\(user)';
            document.getElementsByName('LoginForm[password]')[0].value = '\(pass)';
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
            }, 3000);
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
        showLoading(false)
    }

    // MARK: - Location
    func requestLocationForFichar(tipo: String) {
        // Security check: lComGPS and lComIP
        guard SeguridadUtils.checkSecurity(lComGPS: lComGPS, lComIP: lComIP, lBotonesFichajeMovil: lBotonesFichajeMovil) else {
            showAlert("Fichaje deshabilitado por configuración de seguridad.")
            return
        }
        // Request location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        fichajeAlertTipo = tipo
        showLoading(true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            showLoading(false)
            showAlert("No se pudo obtener la ubicación.")
            return
        }
        // Check for mock location (not trivial in iOS; skip or use heuristics)
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        if lat == 0.0 && lon == 0.0 {
            showLoading(false)
            showAlert("Ubicación inválida.")
            return
        }
        // Build fichaje URL and load in webView
        let tipo = fichajeAlertTipo ?? ""
        let urlFichaje = BuildURLmovil.getCrearFichaje() + "&cTipFic=\(tipo)&tGpsLat=\(lat)&tGpsLon=\(lon)"
        webView.evaluateJavaScript("window.location.href = '\(urlFichaje)';", completionHandler: nil)
        showLoading(false)
        showAlert("Fichaje realizado (\(tipo))")
        resetSessionTimer()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showLoading(false)
        showAlert("Error obteniendo ubicación: \(error.localizedDescription)")
    }

    // MARK: - Alert
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - FicharBottomBarDelegate
extension FicharViewController: FicharBottomBarDelegate {
    func bottomBarDidSelectHome() {
        showFicharPanelView(true)
        showLoading(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showLoading(false)
        }
    }
    func bottomBarDidSelectSection(urlString: String) {
        showFicharPanelView(false)
        showLoading(true)
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showLoading(false)
        }
    }
}

// MARK: - FicharPanelViewDelegate
extension FicharViewController: FicharPanelViewDelegate {
    func ficharPanelDidSelect(tipo: String) {
        requestLocationForFichar(tipo: tipo)
    }
}

// MARK: - FicharNavigationBar
class FicharNavigationBar: UIView {
    var logoutHandler: (() -> Void)?
    private let avatarButton = UIButton(type: .custom)
    private let usernameLabel = UILabel()
    private let logoutButton = UIButton(type: .custom)
    private var imageIndex = 0
    private let images: [UIImage] = [UIImage(named: "cliente32") ?? UIImage()]

    init(username: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.89, green: 0.89, blue: 0.90, alpha: 1)
        avatarButton.setImage(images[imageIndex], for: .normal)
        avatarButton.addTarget(self, action: #selector(changeAvatar), for: .touchUpInside)
        avatarButton.translatesAutoresizingMaskIntoConstraints = false
        avatarButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        avatarButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        usernameLabel.text = username
        usernameLabel.textColor = UIColor(red: 0.46, green: 0.60, blue: 0.71, alpha: 1)
        usernameLabel.font = UIFont.systemFont(ofSize: 18)
        logoutButton.setImage(UIImage(named: "ic_cerrar32"), for: .normal)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        logoutButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [avatarButton, usernameLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        let container = UIStackView(arrangedSubviews: [stack, logoutButton])
        container.axis = .horizontal
        container.alignment = .center
        container.distribution = .equalSpacing
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    @objc private func changeAvatar() {
        imageIndex = (imageIndex + 1) % images.count
        avatarButton.setImage(images[imageIndex], for: .normal)
    }
    @objc private func logoutTapped() {
        logoutHandler?()
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - FicharBottomBar
protocol FicharBottomBarDelegate: AnyObject {
    func bottomBarDidSelectHome()
    func bottomBarDidSelectSection(urlString: String)
}
class FicharBottomBar: UIView {
    weak var delegate: FicharBottomBarDelegate?
    private let homeButton = UIButton(type: .custom)
    private let fichajesButton = UIButton(type: .custom)
    private let incidenciasButton = UIButton(type: .custom)
    private let horariosButton = UIButton(type: .custom)
    private let solicitudesButton = UIButton(type: .custom)
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.89, green: 0.89, blue: 0.90, alpha: 1)
        homeButton.setImage(UIImage(named: "ic_home32_2"), for: .normal)
        homeButton.setTitle("Fichar", for: .normal)
        homeButton.setTitleColor(.black, for: .normal)
        homeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        homeButton.addTarget(self, action: #selector(homeTapped), for: .touchUpInside)
        fichajesButton.setImage(UIImage(named: "ic_fichajes32"), for: .normal)
        fichajesButton.setTitle("Fichajes", for: .normal)
        fichajesButton.setTitleColor(.black, for: .normal)
        fichajesButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        fichajesButton.addTarget(self, action: #selector(fichajesTapped), for: .touchUpInside)
        incidenciasButton.setImage(UIImage(named: "ic_incidencia32"), for: .normal)
        incidenciasButton.setTitle("Incidencias", for: .normal)
        incidenciasButton.setTitleColor(.black, for: .normal)
        incidenciasButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        incidenciasButton.addTarget(self, action: #selector(incidenciasTapped), for: .touchUpInside)
        horariosButton.setImage(UIImage(named: "ic_horario32"), for: .normal)
        horariosButton.setTitle("Horarios", for: .normal)
        horariosButton.setTitleColor(.black, for: .normal)
        horariosButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        horariosButton.addTarget(self, action: #selector(horariosTapped), for: .touchUpInside)
        solicitudesButton.setImage(UIImage(named: "solicitudes32"), for: .normal)
        solicitudesButton.setTitle("Solicitudes", for: .normal)
        solicitudesButton.setTitleColor(.black, for: .normal)
        solicitudesButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        solicitudesButton.addTarget(self, action: #selector(solicitudesTapped), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [
            homeButton, fichajesButton, incidenciasButton, horariosButton, solicitudesButton
        ])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    @objc private func homeTapped() {
        delegate?.bottomBarDidSelectHome()
    }
    @objc private func fichajesTapped() {
        delegate?.bottomBarDidSelectSection(urlString: BuildURLmovil.getFichaje())
    }
    @objc private func incidenciasTapped() {
        delegate?.bottomBarDidSelectSection(urlString: BuildURLmovil.getIncidencia())
    }
    @objc private func horariosTapped() {
        delegate?.bottomBarDidSelectSection(urlString: BuildURLmovil.getHorarios())
    }
    @objc private func solicitudesTapped() {
        delegate?.bottomBarDidSelectSection(urlString: BuildURLmovil.getSolicitudes())
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - FicharPanelView
protocol FicharPanelViewDelegate: AnyObject {
    func ficharPanelDidSelect(tipo: String)
}
class FicharPanelView: UIView {
    weak var delegate: FicharPanelViewDelegate?
    private let entradaButton = UIButton(type: .system)
    private let salidaButton = UIButton(type: .system)
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        entradaButton.setTitle("Fichar Entrada", for: .normal)
        entradaButton.backgroundColor = UIColor(red: 0.46, green: 0.60, blue: 0.71, alpha: 1)
        entradaButton.setTitleColor(.white, for: .normal)
        entradaButton.layer.cornerRadius = 8
        entradaButton.addTarget(self, action: #selector(entradaTapped), for: .touchUpInside)
        salidaButton.setTitle("Fichar Salida", for: .normal)
        salidaButton.backgroundColor = UIColor(red: 0.46, green: 0.60, blue: 0.71, alpha: 1)
        salidaButton.setTitleColor(.white, for: .normal)
        salidaButton.layer.cornerRadius = 8
        salidaButton.addTarget(self, action: #selector(salidaTapped), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [entradaButton, salidaButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            stack.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
        ])
    }
    @objc private func entradaTapped() {
        delegate?.ficharPanelDidSelect(tipo: "E")
    }
    @objc private func salidaTapped() {
        delegate?.ficharPanelDidSelect(tipo: "S")
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - BuildURLmovil (Placeholder)
struct BuildURLmovil {
    static func getIndex() -> String { return "https://kairos24h.com/index" }
    static func getFichaje() -> String { return "https://kairos24h.com/fichaje" }
    static func getIncidencia() -> String { return "https://kairos24h.com/incidencia" }
    static func getHorarios() -> String { return "https://kairos24h.com/horarios" }
    static func getSolicitudes() -> String { return "https://kairos24h.com/solicitudes" }
    static func getCrearFichaje() -> String { return "https://kairos24h.com/crearFichaje" }
}

// MARK: - SeguridadUtils (Placeholder)
struct SeguridadUtils {
    static func checkSecurity(lComGPS: String, lComIP: String, lBotonesFichajeMovil: String) -> Bool {
        // Simulate security check logic
        return (lComGPS == "S" && lComIP == "S" && lBotonesFichajeMovil != "N")
    }
}

// MARK: - MainViewController (Placeholder)
class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let label = UILabel()
        label.text = "Login Screen"
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
    }
}


// Composable principal de la pantalla de fichaje. Muestra WebView con login automático, cuadro para fichar, barra superior e inferior y lógica de navegación.
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun FicharScreen(
    webView: WebView,
    onLogout: () -> Unit
) {
    // Controla si debe mostrarse la pantalla de carga
    var isLoading by remember { mutableStateOf(true) }
    // Controla la visibilidad del cuadro para fichar
    val showCuadroParaFicharState = remember { mutableStateOf(true) }
    // Lista de fichajes realizados (puede ser usada para mostrar historial o control)
    var fichajes by remember { mutableStateOf<List<String>>(emptyList()) }
    // Índice para alternar entre imágenes de usuario (cambia el avatar)
    var imageIndex by remember { mutableIntStateOf(0) }
    // Tipo de alerta de fichaje actual (usado para mostrar mensajes al usuario)
    var fichajeAlertTipo by remember { mutableStateOf<String?>(null) }
    // Ámbito de corrutina usado para manejar delays y tareas asincrónicas
    val scope = rememberCoroutineScope()
    // Controla la visibilidad del diálogo de confirmación para cerrar sesión
    val showLogoutDialog = remember { mutableStateOf(false) }

    // Lista de recursos de imagen para el avatar del usuario
    val imageList = listOf(
        R.drawable.cliente32,
    )

    // Ya no se necesita webViewState; usamos webView directamente
    // Contexto actual de la aplicación (necesario para acceder a preferencias y otros recursos)
    val context = LocalContext.current
    // Accede a las preferencias guardadas del usuario (credenciales y flags)
    val sharedPreferences = context.getSharedPreferences("UserSession", Context.MODE_PRIVATE)
    // Recupera el nombre de usuario desde las preferencias o usa valor por defecto
    val cUsuario = sharedPreferences.getString("usuario", "Usuario") ?: "Usuario"

    // Simula carga inicial de 1,5 segundos antes de mostrar contenido
    LaunchedEffect(Unit) {
        isLoading = true
        delay(1500)
        isLoading = false
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(WindowInsets.systemBars.asPaddingValues())
    ) {
        // Barra superior con avatar del usuario y botón para cerrar sesión
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .height(30.dp)
                .background(Color(0xFFE2E4E5))
                .padding(2.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Sección izquierda: botón avatar que alterna imagen + nombre del usuario
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(
                    onClick = { imageIndex = (imageIndex + 1) % imageList.size }
                ) {
                    Icon(
                        painter = painterResource(id = imageList[imageIndex]),
                        contentDescription = "Usuario",
                        modifier = Modifier.size(30.dp),
                        tint = Color.Unspecified
                    )
                }
                Text(
                    text = cUsuario,
                    color = Color(0xFF7599B6),
                    fontSize = 18.sp
                )
            }
            // Sección derecha: botón para cerrar sesión, abre un diálogo de confirmación
            IconButton(onClick = { showLogoutDialog.value = true }) {
                Icon(
                    painter = painterResource(id = R.drawable.ic_cerrar32),
                    contentDescription = "Cerrar sesión",
                    modifier = Modifier.size(30.dp),
                    tint = Color.Unspecified
                )
            }
        }

        // Contenedor central que ocupa el espacio restante; contiene el WebView, cuadro de fichaje y mensajes
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
        ) {
            // El WebView ya está en el FrameLayout de la Activity, no se necesita AndroidView aquí.

            // Pantalla de carga que se muestra mientras se realiza la autenticación automática
            LoadingScreen(isLoading = isLoading)

            // Cuadro emergente con botones de fichaje (Entrada/Salida) que solicita la ubicación GPS
            if (showCuadroParaFicharState.value) {
                // Lógica para mostrar u ocultar los botones de fichaje según lBotonesFichajeMovil
                val lBotonesFichajeMovil = sharedPreferences.getString("lBotonesFichajeMovil", "") ?: ""
                val mostrarBotones = lBotonesFichajeMovil != "N"
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .zIndex(1f)
                        .background(Color.White)
                ) {
                    CuadroParaFichar(
                        isVisibleState = showCuadroParaFicharState,
                        fichajes = fichajes,
                        onFichaje = { tipo ->
                            obtenerCoord(
                                context,
                                onLocationObtained = { lat, lon ->
                                    if (lat == 0.0 || lon == 0.0) {
                                        Log.e("Fichar", "Ubicación inválida, no se enviará el fichaje")
                                        fichajeAlertTipo = "Ubicación inválida"
                                        return@obtenerCoord
                                    }
                                    fichajeAlertTipo = tipo
                                },
                                onShowAlert = { alertTipo ->
                                    fichajeAlertTipo = alertTipo
                                }
                            )
                        },
                        onShowAlert = { alertTipo ->
                            fichajeAlertTipo = alertTipo
                        },
                        webViewState = remember { mutableStateOf(webView) },
                        mostrarBotonesFichaje = mostrarBotones
                    )
                }
            }

            // Muestra un mensaje emergente si hay un error o advertencia en el proceso de fichaje
            fichajeAlertTipo?.let { tipo ->
                MensajeAlerta(
                    tipo = tipo,
                    onClose = { fichajeAlertTipo = null }
                )
            }
        }

        // Barra inferior con navegación entre secciones y botón para mostrar el cuadro de fichaje
        BottomNavigationBar(
            onNavigate = { url ->
                isLoading = true
                showCuadroParaFicharState.value = false
                webView.loadUrl(url)
                scope.launch {
                    delay(1500)
                    isLoading = false
                }
            },
            onToggleFichar = { showCuadroParaFicharState.value = true },
            hideCuadroParaFichar = { showCuadroParaFicharState.value = false },
            setIsLoading = { isLoading = it },
            scope = scope,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp)
        )
    }

    // Diálogo modal que solicita confirmación para cerrar la sesión
    if (showLogoutDialog.value) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog.value = false },
            title = {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(Color(0xFF7599B6))
                        .padding(12.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "¿Cerrar sesión?",
                        color = Color.White,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            },
            text = {
                Text(
                    "Si continuas cerrarás tu sesión, ¿Seguro que es lo que quieres hacer?",
                    color = Color.Black
                )
            },
            confirmButton = {},
            dismissButton = {
                Row(modifier = Modifier.fillMaxWidth()) {
                    Button(
                        onClick = {
                            showLogoutDialog.value = false
                            webView.apply {
                                clearCache(true)
                                clearHistory()
                            }
                            CookieManager.getInstance().removeAllCookies(null)
                            CookieManager.getInstance().flush()
                            AuthManager.clearAllUserData(context)
                            onLogout()
                        },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF7599B6),
                            contentColor = Color.White
                        ),
                        shape = RectangleShape
                    ) {
                        Text("Sí")
                    }

                    Spacer(modifier = Modifier.width(30.dp))

                    Button(
                        onClick = {
                            showLogoutDialog.value = false
                        },
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF7599B6),
                            contentColor = Color.White
                        ),
                        shape = RectangleShape
                    ) {
                        Text("No")
                    }
                }
            },
            shape = RoundedCornerShape(30.dp)
        )
    }
}

// ================================== Preview de la pantalla ==================================
@Composable
@Preview(showBackground = true)
fun PreviewFicharScreen() {
    // No se puede previsualizar el WebView real en preview, así que pasamos un dummy
    FicharScreen(
        webView = WebView(LocalContext.current),
        onLogout = {}
    )
}
// ================================== Preview de la pantalla ==================================



internal fun fichar(context: Context, tipo: String, webView: WebView) {
    // Verifica si se tiene permiso de ubicación fina antes de continuar
    val hasPermission = ContextCompat.checkSelfPermission(
        context, Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED

    // Si no hay permisos de GPS, muestra un mensaje y no continúa con el fichaje
    if (!hasPermission) {
        Log.e("Fichar", "No se cuenta con el permiso ACCESS_FINE_LOCATION")
        Toast.makeText(context, "Debe aceptar los permisos de GPS para poder fichar.", Toast.LENGTH_SHORT).show()
        return
    }

    // Intenta obtener las coordenadas del dispositivo y realizar el fichaje con ellas
    try {
        obtenerCoord(
            context,
            onLocationObtained = { lat, lon ->
                if (lat == 0.0 || lon == 0.0) {
                    Log.e("Fichar", "Ubicación inválida, no se enviará el fichaje")
                    return@obtenerCoord
                }

                // Construye la URL de fichaje con el tipo y las coordenadas
                val urlFichaje = BuildURLmovil.getCrearFichaje(context) +
                        "&cTipFic=$tipo" +
                        "&tGpsLat=$lat" +
                        "&tGpsLon=$lon"

                Log.d("Fichar", "URL que se va a enviar desde WebView: $urlFichaje")
                // Ejecuta la URL de fichaje en el WebView
                webView.evaluateJavascript("window.location.href = '$urlFichaje';", null)
            },
            onShowAlert = { alertTipo ->
                Log.e("Fichar", "Alerta: $alertTipo")
            }
        )
    } catch (e: SecurityException) {
        Log.e("Fichar", "Error de seguridad al acceder a la ubicación: ${e.message}")
    }
}

fun obtenerCoord(
    context: Context,
    onLocationObtained: (lat: Double, lon: Double) -> Unit,
    onShowAlert: (String) -> Unit
) {
    // Obtiene los valores de control de seguridad desde AuthManager
    val (_, _, _, lComGPS, lComIP, lBotonesFichajeMovil) = AuthManager.getUserCredentials(context)
    // Log para verificar los valores de seguridad
    Log.d("Seguridad", "lComGPS=$lComGPS, lComIP=$lComIP, lBotonesFichajeMovil=$lBotonesFichajeMovil")
    // Registra advertencias si alguna de las condiciones de seguridad deshabilita el fichaje
    if (lComGPS != "S") Log.w("Seguridad", "El fichaje está deshabilitado por GPS: lComGPS=$lComGPS")
    if (lComIP != "S") Log.w("Seguridad", "El fichaje está deshabilitado por IP: lComIP=$lComIP")
    // Define si se debe validar el GPS e IP para el fichaje
    val validarGPS = lComGPS == "S"
    val validarIP = lComIP == "S"

    val scope = CoroutineScope(Dispatchers.Main)
    scope.launch {
        // Verifica que se cumplan las condiciones de seguridad configuradas antes de obtener ubicación
        val permitido = SeguridadUtils.checkSecurity(
            context,
            if (validarGPS) "S" else "N",
            if (validarIP) "S" else "N",
            "S"
        ) { mensaje ->
            onShowAlert(mensaje)
        }
        if (!permitido) return@launch

        // Cliente de ubicación para obtener la última localización disponible
        val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)

        // Verifica que los permisos de GPS estén concedidos
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.e("Fichar", "No se cuenta con los permisos de ubicación.")
            onShowAlert("PROBLEMA GPS")
            return@launch
        }

        // Verifica que el GPS esté activado en el dispositivo
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (!locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            Log.e("Fichar", "GPS desactivado.")
            onShowAlert("PROBLEMA GPS")
            return@launch
        }

        // Intenta obtener la última ubicación del dispositivo y valida si es real o falsa
        fusedLocationClient.lastLocation.addOnSuccessListener { location ->
            if (location == null) {
                Log.e("Fichar", "No se pudo obtener la ubicación.")
                onShowAlert("PROBLEMA GPS")
                return@addOnSuccessListener
            }

            // Verifica si la ubicación está siendo falsificada (mock location)
            if (SeguridadUtils.isMockLocationEnabled()) {
                Log.e("Fichar", "Ubicación falsa detectada.")
                onShowAlert("POSIBLE UBI FALSA")
                return@addOnSuccessListener
            }

            onLocationObtained(location.latitude, location.longitude)
        }.addOnFailureListener { e ->
            Log.e("Fichar", "Error obteniendo ubicación: ${e.message}")
            onShowAlert("PROBLEMA GPS")
        }
    }
}
//============================================== FICHAJE DE LA APP =====================================

// Barra de navegación inferior que permite acceder a distintas secciones (Fichajes, Incidencias, etc.) y abrir el cuadro para fichar
@Composable
fun BottomNavigationBar(
    onNavigate: (String) -> Unit,
    onToggleFichar: () -> Unit,
    modifier: Modifier = Modifier,
    hideCuadroParaFichar: () -> Unit,
    setIsLoading: (Boolean) -> Unit,
    scope: CoroutineScope
) {
    // Controla si se ha pulsado el botón de fichar (para alternar su estado visual o funcional)
    var isChecked by remember { mutableStateOf(false) }

    // Contenedor horizontal que agrupa todos los botones de navegación
    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(Color(0xFFE2E4E5))
            .padding(2.dp)
            .zIndex(3f),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Botón de fichar: lanza el cuadro para fichar y activa animación de carga
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            IconButton(
                onClick = {
                    isChecked = !isChecked
                    setIsLoading(true)
                    scope.launch {
                        delay(1500)
                        setIsLoading(false)
                    }
                    onToggleFichar()
                }
            ) {
                Icon(
                    painter = painterResource(id = R.drawable.ic_home32_2),
                    contentDescription = "Fichar",
                    modifier = Modifier.size(32.dp),
                    tint = Color.Unspecified
                )
            }
            Text(text = "Fichar", textAlign = TextAlign.Center, modifier = Modifier.padding(top = 2.dp))
        }
        val context = LocalContext.current

        // Botón de navegación que cambia de sección y oculta el cuadro para fichar
        NavigationButton("Fichajes", R.drawable.ic_fichajes32) {
            hideCuadroParaFichar()
            val dominio = BuildURLmovil.getHost(context)
            val cookieManager = CookieManager.getInstance()
            val cookie = cookieManager.getCookie(dominio)
            if (!cookie.isNullOrEmpty()) {
                cookieManager.setCookie(dominio, cookie)
                cookieManager.flush()
            }
            onNavigate(BuildURLmovil.getFichaje(context))
        }
        // Botón de navegación que cambia de sección y oculta el cuadro para fichar
        NavigationButton("Incidencias", R.drawable.ic_incidencia32) {
            hideCuadroParaFichar()
            val dominio = BuildURLmovil.getHost(context)
            val cookieManager = CookieManager.getInstance()
            val cookie = cookieManager.getCookie(dominio)
            if (!cookie.isNullOrEmpty()) {
                cookieManager.setCookie(dominio, cookie)
                cookieManager.flush()
            }
            onNavigate(BuildURLmovil.getIncidencia(context))
        }
        // Botón de navegación que cambia de sección y oculta el cuadro para fichar
        NavigationButton("Horarios", R.drawable.ic_horario32) {
            hideCuadroParaFichar()
            val dominio = BuildURLmovil.getHost(context)
            val cookieManager = CookieManager.getInstance()
            val cookie = cookieManager.getCookie(dominio)
            if (!cookie.isNullOrEmpty()) {
                cookieManager.setCookie(dominio, cookie)
                cookieManager.flush()
            }
            onNavigate(BuildURLmovil.getHorarios(context))
        }
        // Botón de navegación que cambia de sección y oculta el cuadro para fichar
        NavigationButton("Solicitudes", R.drawable.solicitudes32) {
            hideCuadroParaFichar()
            val dominio = BuildURLmovil.getHost(context)
            val cookieManager = CookieManager.getInstance()
            val cookie = cookieManager.getCookie(dominio)
            if (!cookie.isNullOrEmpty()) {
                cookieManager.setCookie(dominio, cookie)
                cookieManager.flush()
            }
            onNavigate(BuildURLmovil.getSolicitudes(context))
        }
    }
}

// Botón reutilizable de navegación inferior, con icono e identificador de sección
@Composable
fun NavigationButton(text: String, iconResId: Int, onClick: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        IconButton(onClick = onClick) {
            Icon(
                painter = painterResource(id = iconResId),
                contentDescription = text,
                modifier = Modifier.size(32.dp),
                tint = Color.Unspecified
            )
        }
        Text(
            text = text,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(top = 4.dp)
        )
    }
}
//============================== CUADRO PARA FICHAR ======================================

// Pantalla de carga que muestra un GIF mientras se carga la vista principal (WebView o datos)
@Composable
fun LoadingScreen(isLoading: Boolean) {
    if (isLoading) {
        val context = LocalContext.current
        val imageLoader = ImageLoader.Builder(context)
            .components {
                add(ImageDecoderDecoder.Factory())
            }
            .build()

        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.White)
                .zIndex(2f),
            contentAlignment = Alignment.Center
        ) {
            AsyncImage(
                model = ImageRequest.Builder(context)
                    .data(R.drawable.version_2)
                    .crossfade(true)
                    .build(),
                imageLoader = imageLoader,
                contentDescription = "Loading GIF",
                modifier = Modifier.size(200.dp)
            )
        }
    }
}
