//
//  MenuView.swift
//  Chess
//
//  Created by exerhythm on 9/29/21.
//

import SwiftUI

struct MenuView: View {
    @State var showingSettings = false
    @State var showingPremium = false
    
    @ObservedObject private var settings = AppEnvironment.shared.settings
    
    var body: some View {
        NavigationStack {
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
                    
                    NavigationLink {
                        GameView(shown: .constant(true), gameType: .overTheBoard)
                    } label: {
                        MenuButton(image: "ipad", text: "Play")
                    }
                    if settings.proEnabled {
                        NavigationLink {
                            GameView(shown: .constant(true), gameType: .puzzle)
                        } label: {
                            MenuButton(image: "puzzlepiece", text: "Custom Position")
                        }
                    } else {
                        Button(action: {
                            showingPremium = true
                        }) {
                            MenuButton(image: "puzzlepiece", text: "Custom Position")
                        }
                    }

                    NavigationLink {
                        SavedGamesView()
                    } label: {
                        MenuButton(image: "clock.arrow.circlepath", text: "Saved Games")
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
