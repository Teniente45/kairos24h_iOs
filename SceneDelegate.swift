//
//  SceneDelegate.swift
//  kairos24h
//
//  Created by Juan López Marín on 16/6/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let loginVC = paginaLogin()
        let navController = UINavigationController(rootViewController: loginVC)
        window.rootViewController = navController
        self.window = window
        window.makeKeyAndVisible()
    }
}
