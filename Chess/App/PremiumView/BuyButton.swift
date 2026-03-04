//
//  BuyButton.swift
//  Chess
//
//  Created by exerhythm on 7/27/21.
//

import SwiftUI

@available(iOS 13.0, *)
struct BuyButton: View {
    @ObservedObject var storeManager: StoreManager
    @ObservedObject private var settings = AppEnvironment.shared.settings
    
    var body: some View {
        let isPurchased = settings.proEnabled
        Button(action: {
            storeManager.purchaseProVersion()
        }) {
            Text(!isPurchased ? "Buy for".localized + " " + "\(storeManager.proVersionProduct?.localizedPrice ?? "$1.99")" : "Purchased. Thanks!".localized)
                .font(.headline)
                .padding(12)
                .frame(maxWidth: .infinity)
                .foregroundColor(!isPurchased ? .white : PremiumPalette.textPrimary)
        }
        .background((!isPurchased ? PremiumPalette.accent : PremiumPalette.iconBackground).clipShape(Capsule()))
        .overlay(
            Capsule()
                .stroke((!isPurchased ? PremiumPalette.border.opacity(0.28) : PremiumPalette.border.opacity(0.18)), lineWidth: 1)
        )
        .onAppear(perform: {
            storeManager.getProVersion()
        })
        .disabled(isPurchased)
    }
}


struct BuyButton_Previews: PreviewProvider {
    static var previews: some View {
        BuyButton(storeManager: StoreManager())
            .previewLayout(.sizeThatFits)
            .frame(width: 300, height: 48, alignment: .center)
    }
}
