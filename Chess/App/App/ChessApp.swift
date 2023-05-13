//
//  ChessApp.swift
//  Chess
//
//  Created by sourcelocation on 09/04/2023.
//

import SwiftUI
import SwiftyStoreKit

@main
struct ChessApp: App {
    var body: some Scene {
        WindowGroup {
            MenuView()
        }
    }
    
    init() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                case .failed, .purchasing, .deferred:
                    break
                @unknown default:
                    fatalError()
                }
            }
        }
        UIApplication.shared.isIdleTimerDisabled = true
    }
}
