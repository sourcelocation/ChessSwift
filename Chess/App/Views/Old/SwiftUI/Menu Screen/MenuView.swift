//
//  MenuView.swift
//  Chess
//
//  Created by exerhythm on 9/29/21.
//

import SwiftUI

//@available(iOS 13.0.0, *)
//struct MenuView: View {
//    @State var showOfflineGame = false
//    @State var showOnlineGame = false
//    
//    @StateObject var settings = SettingsStore()
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                Color(red: 0.9190433025, green: 0.8973273635, blue: 0.8671943545)
//                    .edgesIgnoringSafeArea(.all)
//                VStack {
//                    Spacer()
//                    Image("Logo")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(maxWidth: 330)
////                        .padding(32)
//                        .padding(.bottom,24)
//                        .padding(.horizontal, 32)
//                    
//                    NavigationLink(destination: GameView(shown: $showOfflineGame, online: false), isActive: $showOfflineGame) {
//                        MenuButton(image: "ipad", text: "Play")
//                            .padding(8)
//                            .padding(.horizontal, 20)
//                    }
//                    NavigationLink(destination: GameView(shown: $showOnlineGame, online: true), isActive: $showOnlineGame) {
//                        MenuButton(image: "globe", text: "Online game")
//                            .padding(8)
//                            .padding(.horizontal, 20)
//                    }
//                    
//                    HStack(spacing:20) {
//                        Button(action: {
//                            
//                        }) {
//                            Image(systemName: "gearshape")
//                        }
//                        Button(action: {
//                            
//                        }) {
//                            Image(systemName: "crown")
//                        }
//                    }
//                    .foregroundColor(.black)
//                    .font(.system(size: 24))
//                    .padding(4)
//                    Spacer()
//                }
//                .ignoresSafeArea()
////                .padding()
//            }
//            .navigationBarHidden(true)
//        }
//        .navigationViewStyle(StackNavigationViewStyle())
//        .environmentObject(settings)
//    }
//}
//
//@available(iOS 13.0.0, *)
//struct MenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        if #available(iOS 15.0, *) {
//            MenuView()
//                .previewInterfaceOrientation(.landscapeLeft)
//        } else {
//            // Fallback on earlier versions
//        }
//    }
//}
