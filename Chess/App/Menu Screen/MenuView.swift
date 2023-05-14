//
//  MenuView.swift
//  Chess
//
//  Created by exerhythm on 9/29/21.
//

import SwiftUI

struct MenuView: View {
    @State var showOfflineGame = false
    @State var showOnlineGame = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.init(rgb: 0xF4EDE3))
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Spacer()
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 330)
//                        .padding(32)
                        .padding(.bottom,24)
                        .padding(.horizontal, 32)
                    
                    NavigationLink(destination: GameView(shown: $showOfflineGame, online: false), isActive: $showOfflineGame) {
                        MenuButton(image: "ipad", text: "Play")
                            .padding(8)
                            .padding(.horizontal, 20)
                    }
                    NavigationLink(destination: GameView(shown: $showOnlineGame, online: true), isActive: $showOnlineGame) {
                        MenuButton(image: "globe", text: "Online game")
                            .padding(8)
                            .padding(.horizontal, 20)
                    }
                    
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
                    .padding(4)
                    Spacer()
                }
                .ignoresSafeArea()
//                .padding()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
