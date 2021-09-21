//
//  SceneDelegate.swift
//  Chess
//
//  Created by exerhythm on 7/11/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        
        window?.overrideUserInterfaceStyle = .light
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        print("Normal exit")
        UserDefaults.standard.set(false, forKey: "didntEndSession")
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        UserDefaults.standard.set(false, forKey: "didntEndSession")
    }
}
