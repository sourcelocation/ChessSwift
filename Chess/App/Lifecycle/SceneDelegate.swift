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
//            window.backgroundColor = #colorLiteral(red: 0.8861198425, green: 0.8416082263, blue: 0.8121766448, alpha: 1)
//            window.overrideUserInterfaceStyle = .light
//            window.rootViewController = UIHostingController(rootView: MenuView())
//            window.rootViewController?.view.backgroundColor = #colorLiteral(red: 0.8861198425, green: 0.8416082263, blue: 0.8121766448, alpha: 1)
//            self.window = window
//            window.makeKeyAndVisible()
//
//            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.AccentColor)
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

extension Color {
    public static let AccentColor = Color("AccentColor")
}
extension UIView {

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}
