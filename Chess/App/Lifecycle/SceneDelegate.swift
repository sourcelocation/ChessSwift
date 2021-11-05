//
//  SceneDelegate.swift
//  Chess
//
//  Created by exerhythm on 7/11/21.
//

import UIKit
import SwiftUI

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
//        if let windowScene = scene as? UIWindowScene {
//            let window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .light
//            window.rootViewController = UIHostingController(rootView: MenuView())
//            self.window = window
//            window.makeKeyAndVisible()
//        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        print("Normal exit")
        UserDefaults.standard.set(false, forKey: "didntEndSession")
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        UserDefaults.standard.set(false, forKey: "didntEndSession")
    }
}

@available(iOS 13.0.0, *)
struct AppPreview: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
