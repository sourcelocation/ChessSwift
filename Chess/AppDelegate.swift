//
//  AppDelegate.swift
//  Chess
//
//  Created by Матвей Анисович on 4/4/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }


}

extension Sequence  {
    func contains<T, U>(_ tuple: (T, U)) -> Bool where T: Equatable, U: Equatable, Element == (T,U) {
        contains { $0 == tuple }
    }
    func contains<T, U, V>(_ tuple: (T, U, V)) -> Bool where T: Equatable, U: Equatable, V: Equatable, Element == (T,U,V) {
        contains { $0 == tuple }
    }
    func contains<T, U, V, W>(_ tuple: (T, U, V, W)) -> Bool where T: Equatable, U: Equatable, V: Equatable, W: Equatable,Element == (T, U, V, W) {
        contains { $0 == tuple }
    }
    func contains<T, U, V, W, X>(_ tuple: (T, U, V, W, X)) -> Bool where T: Equatable, U: Equatable, V: Equatable, W: Equatable, X: Equatable, Element == (T, U, V, W, X) {
        contains { $0 == tuple }
    }
    func contains<T, U, V, W, X, Y>(_ tuple: (T, U, V, W, X, Y)) -> Bool where T: Equatable, U: Equatable, V: Equatable, W: Equatable, X: Equatable, Y: Equatable, Element == (T, U, V, W, X, Y) {
        contains { $0 == tuple }
    }
}
