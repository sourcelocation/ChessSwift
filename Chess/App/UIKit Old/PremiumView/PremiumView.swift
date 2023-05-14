//
//  PremiumView.swift
//  Chess
//
//  Created by exerhythm on 7/26/21.
//

import SwiftUI


struct PremiumView: View {
    @StateObject var storeManager = StoreManager()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Binding var showModal: Bool
    
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 0.9137254902, green: 0.8980392157, blue: 0.8705882353, alpha: 1))
                .edgesIgnoringSafeArea(.all)
            HStack {
                VStack {
                    Button(action: {
                        showModal = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24, alignment: .center)
                            .padding()
                            .foregroundColor(.accentColor)
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
                        Text("Restore purchase".localized)
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
                                Text("Restore purchase".localized)
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
        .foregroundColor(.black)
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
            Text("Pro version".localized)
                .font(.largeTitle)
                .bold()
                .padding(2)
            Text("Chess: 2 Players".localized)
        }
    }
}


struct PremiumList: View {
    var items: [Feature] = [
        Feature(title: "No undo limits".localized, image: "arrow.uturn.left"),
        Feature(title: "Chess clock".localized, image: "clock"),
        Feature(title: "Puzzle configurator".localized, image: "puzzlepiece"),
        Feature(title: "Draggable pieces".localized, image: "hand.draw"),
        Feature(title: "More settings".localized, image: "gearshape"),
    ]
    var body: some View {
        Text("Features")
            .font(.title2)
            .bold()
            .padding(.bottom, 4)
        
        VStack(alignment: .leading, spacing: 0, content: {
            ForEach(items) { item in
                FeatureListItem(title: item.title, image: item.image)
            }
            .padding(10)
        })
    }
    
    struct Feature: Identifiable {
        var id = UUID()
        var title: String
        var image: String
    }
}


struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumView(showModal: .constant(true))
    }
}
