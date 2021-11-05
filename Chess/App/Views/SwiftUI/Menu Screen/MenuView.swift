//
//  MenuView.swift
//  Chess
//
//  Created by exerhythm on 9/29/21.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct MenuView: View {
    
    var body: some View {
        ZStack {
            Color(red: 0.9190433025, green: 0.8973273635, blue: 0.8671943545)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 330)
                    .padding(32)
                    .padding(.bottom,64)
                
                MenuButton(image: "ipad", text: "Play", action: {
                    let vc = UIApplication.shared.windows.first!.rootViewController as! UIHostingController<MenuView>
                    vc.present(UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GameVC"), animated: true)
                })
                    .padding(8)
                MenuButton(image: "globe", text: "Online game", action: {
                    
                })
                    .padding(8)
                
                HStack(spacing:20) {
                    Button(action: {
                        
                    }) {
                        Image(systemName: "gearshape")
                    }
                    Button(action: {
                        
                    }) {
                        Image(systemName: "crown")
                    }
                }
                .foregroundColor(.black)
                .font(.system(size: 24))
                .padding(8)
            }
            .padding(32)
        }
    }
}

@available(iOS 13.0.0, *)
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 15.0, *) {
            MenuView()
                .previewInterfaceOrientation(.portrait)
        } else {
            // Fallback on earlier versions
        }
    }
}
