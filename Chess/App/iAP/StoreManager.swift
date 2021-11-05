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
        SwiftyStoreKit.retrieveProductsInfo(["io.github.exerhythm.Chess.Pro"]) { result in
            self.proVersionProduct = result.retrievedProducts.first
        }
    }
    func purchaseProVersion() {
        #if DEBUG
        UserDefaults.standard.set(true, forKey: "pro")
        self.transactionState = .purchased
        (UIApplication.shared.windows[0].rootViewController as! GameViewController).board?.proVersion = true
        #endif
        SwiftyStoreKit.purchaseProduct("io.github.exerhythm.Chess.Pro", quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                UserDefaults.standard.set(true, forKey: "pro")
                self.transactionState = .purchased
                (UIApplication.shared.windows[0].rootViewController as! GameViewController).board?.proVersion = true
            case .error(let error):
                switch error.code {
                case .unknown:
                    print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                default: print((error as NSError).localizedDescription)
                }
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
