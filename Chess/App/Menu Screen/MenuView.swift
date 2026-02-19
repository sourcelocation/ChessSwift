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
    @State var showPuzzleGame = false
    
    @State var showingSettings = false
    @State var showingPremium = false
    
    @AppStorage("pro") var isPro = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.init(rgb: 0xF4EDE3))
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 12) {
                    Spacer()
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 330)
//                        .padding(32)
                        .padding(.bottom,24)
                        .padding(.horizontal, 32)
                    
                    NavigationLink(destination: GameView(shown: $showOfflineGame, gameType: .overTheBoard), isActive: $showOfflineGame) {
                        MenuButton(image: "ipad", text: "Play")
                    }
                    NavigationLink(destination: GameView(shown: $showOnlineGame, gameType: .online), isActive: $showOnlineGame) {
                        MenuButton(image: "globe", text: "Online game")
                    }
                    if isPro {
                        NavigationLink(destination: GameView(shown: $showPuzzleGame, gameType: .puzzle), isActive: $showPuzzleGame) {
                            MenuButton(image: "puzzlepiece", text: "Custom Position")
                        }
                    } else {
                        Button(action: {
                            showingPremium = true
                        }) {
                            MenuButton(image: "puzzlepiece", text: "Custom Position")
                        }
                    }
                    
                    HStack(spacing:20) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                        }
                        Button(action: {
                            showingPremium = true
                        }) {
                            Image(systemName: "crown")
                        }
                    }
                    .foregroundColor(.black)
                    .font(.system(size: 24))
                    .padding(4)
                    Spacer()
                }
                .padding(.horizontal, 32)
                .ignoresSafeArea()
//                .padding()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingPremium) {
            PremiumView(showModal: $showingPremium)
        }
    }
}


struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
