//
//  StoreManager.swift
//  Chess
//
//  Created by exerhythm on 7/27/21.
//

import Foundation
import StoreKit
import SwiftyStoreKit

@available(iOS 13.0, *)
class StoreManager: NSObject, ObservableObject {
    @Published var proVersionProduct: SKProduct?
    @Published var transactionState: SKPaymentTransactionState?
    
    func getProVersion() {
        SwiftyStoreKit.retrieveProductsInfo(["io.github.exerhythm.Chess.Pro"]) { [weak self] result in
            self?.proVersionProduct = result.retrievedProducts.first
        }
        
    }
    func purchaseProVersion() {
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "pro")
        self.transactionState = .purchased
        #endif
        SwiftyStoreKit.purchaseProduct("io.github.exerhythm.Chess.Pro", quantity: 1, atomically: true) { [weak self] result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                UserDefaults.standard.set(true, forKey: "pro")
                self?.transactionState = .purchased
            case .error, .deferred: break
            }
        }
    }
    func restoreProVersion() {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
            }
            else if results.restoredPurchases.count > 0 {
                print("Restore Success: \(results.restoredPurchases)")
                UserDefaults.standard.set(true, forKey: "pro")
                self.transactionState = .restored
            }
            else {
                print("Nothing to Restore")
            }
        }
    }
}
