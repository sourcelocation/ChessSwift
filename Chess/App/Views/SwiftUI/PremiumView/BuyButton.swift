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
    
    var body: some View {
        Button(action: {
            storeManager.purchaseProVersion()
        }) {
            Text(!UserDefaults.standard.bool(forKey: "pro") ? "Buy for \(storeManager.proVersionProduct?.localizedPrice ?? "$1.99")" : "Purchased. Thanks!")
                .font(.headline)
                .padding(12)
                .frame(maxWidth: .infinity)
                .disabled(UserDefaults.standard.bool(forKey: "pro"))
                .foregroundColor(.white)
        }
        .background(Color(#colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 0.7340561224)).clipShape(Capsule()))
        .onAppear(perform: {
            storeManager.getProVersion()
        })
        .disabled(UserDefaults.standard.bool(forKey: "pro"))
    }
}

@available(iOS 13.0.0, *)
struct BuyButton_Previews: PreviewProvider {
    static var previews: some View {
        BuyButton(storeManager: StoreManager())
            .previewLayout(.sizeThatFits)
            .frame(width: 300, height: 48, alignment: .center)
    }
}
