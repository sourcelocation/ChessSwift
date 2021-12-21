//
//  PremiumView.swift
//  Chess
//
//  Created by exerhythm on 7/26/21.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct PremiumView: View {
    @StateObject var storeManager = StoreManager()
    @Environment(\.verticalSizeClass) var verticalSizeClass
//    @Binding var showModal: Bool
    var dismissAction: () -> ()
    
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.8860356212, green: 0.8416687846, blue: 0.812075913, alpha: 1))
                .edgesIgnoringSafeArea(.all)
            HStack {
                VStack {
                    Button(action: {
                        dismissAction()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24, alignment: .center)
                            .foregroundColor(.init(.sRGB, white: 0.5, opacity: 0.5))
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
            if verticalSizeClass == .regular {
                VStack {
                    Header()
                    Spacer()
                    PremiumList()
                    Spacer()
                    BuyButton(storeManager: storeManager)
                        .padding(.horizontal, 32)
                        .padding(.top, 32)
                    Button(action:{
                        storeManager.restoreProVersion()
                    }) {
                        Text("Restore purchase")
                            .padding(8)
                            .font(.subheadline)
                            .padding(.bottom, 16)
                    }
                }
            } else {
                GeometryReader { geometry in
                    HStack {
                        VStack {
                            Header()
                            Spacer()
                            BuyButton(storeManager: storeManager)
                                .padding(.horizontal, 32)
                                .padding(.top, 32)
                            Button(action:{
                                storeManager.restoreProVersion()
                            }) {
                                Text("Restore purchase")
                                    .padding(8)
                                    .font(.subheadline)
                                    .padding(.bottom, 16)
                            }
                        }
                        .frame(width: geometry.size.width * 0.6)
                        
                        Spacer()
                        VStack {
                            Spacer()
                            PremiumList()
                            Spacer()
                        }
                        .padding()
                        Spacer()
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, *)
struct Header: View {
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "crown")
                Image(systemName: "checkerboard.rectangle")
            }
            .font(.system(size: 36))
            .foregroundColor(Color(#colorLiteral(red: 0.4086923003, green: 0.2684660256, blue: 0.1772648394, alpha: 1)))
            .padding(.top, 24)
            Text("Pro version")
                .font(.largeTitle)
                .bold()
                .padding(2)
            Text("Chess: 2 Players")
        }
    }
}

@available(iOS 13.0.0, *)
struct PremiumList: View {
    var items: [Feature] = [
        Feature(title: "No undo limits", image: "arrow.uturn.left"),
        Feature(title: "Chess clock", image: "clock"),
        Feature(title: "Puzzle configurator", image: "puzzlepiece"),
        Feature(title: "Drag pieces", image: "hand.draw"),
        Feature(title: "More settings", image: "gearshape"),
    ]
    var body: some View {
        Text("Features")
            .font(.title)
            .bold()
            .padding(.bottom, 4)
        
        VStack(alignment: .leading, spacing: 0, content: {
            ForEach(items) { item in
                FeatureListItem(title: item.title, image: item.image)
            }
            .padding(16)
        })
    }
    
    struct Feature: Identifiable {
        var id = UUID()
        var title: String
        var image: String
    }
}

@available(iOS 13.0.0, *)
struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumView(dismissAction:{})
    }
}
