//
//  ChessApp.swift
//  Chess
//
//  Created by sourcelocation on 09/04/2023.
//

import SwiftUI
import Darwin

@main
struct ChessApp: App {
    @StateObject private var environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            MenuView()
                .environmentObject(environment.settings)
        }
    }
    
    init() {
        signal(SIGPIPE, SIG_IGN)
        AppEnvironment.shared.purchaseService.configureTransactions()
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
