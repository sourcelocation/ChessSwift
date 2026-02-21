import Foundation
import UIKit
import StoreKit
import SwiftyStoreKit

@MainActor
protocol ReviewPromptService {
    func requestIfNeeded()
}

protocol PurchaseService {
    func configureTransactions()
}

@MainActor
final class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment.live()

    let settings: AppSettings
    let gameRepository: GameRepository
    let reviewPrompt: ReviewPromptService
    let purchaseService: PurchaseService

    init(
        settings: AppSettings,
        gameRepository: GameRepository,
        reviewPrompt: ReviewPromptService,
        purchaseService: PurchaseService
    ) {
        self.settings = settings
        self.gameRepository = gameRepository
        self.reviewPrompt = reviewPrompt
        self.purchaseService = purchaseService
    }

    static func live() -> AppEnvironment {
        let settings = AppSettings()
        return AppEnvironment(
            settings: settings,
            gameRepository: DefaultGameRepository(),
            reviewPrompt: DefaultReviewPromptService(settings: settings),
            purchaseService: SwiftyStoreKitPurchaseService()
        )
    }
}

@MainActor
struct DefaultReviewPromptService: ReviewPromptService {
    let settings: AppSettings

    func requestIfNeeded() {
        guard !settings.hasReviewed else { return }
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        settings.hasReviewed = true
    }
}

struct SwiftyStoreKitPurchaseService: PurchaseService {
    func configureTransactions() {
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
                    break
                }
            }
        }
    }
}
