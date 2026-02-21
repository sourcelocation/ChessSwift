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
        Button(action: {
            storeManager.purchaseProVersion()
        }) {
            Text(!settings.proEnabled ? "Buy for".localized + " " + "\(storeManager.proVersionProduct?.localizedPrice ?? "$1.99")" : "Purchased. Thanks!".localized)
                .font(.headline)
                .padding(12)
                .frame(maxWidth: .infinity)
                .disabled(settings.proEnabled)
                .foregroundColor(.white)
        }
        .background(Color(#colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 0.7340561224)).clipShape(Capsule()))
        .onAppear(perform: {
            storeManager.getProVersion()
        })
        .disabled(settings.proEnabled)
    }
}


struct BuyButton_Previews: PreviewProvider {
    static var previews: some View {
        BuyButton(storeManager: StoreManager())
            .previewLayout(.sizeThatFits)
            .frame(width: 300, height: 48, alignment: .center)
    }
}
