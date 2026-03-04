//
//  PremiumView.swift
//  Chess
//
//  Created by exerhythm on 7/26/21.
//

import SwiftUI

enum PremiumPalette {
    static let appBackground = Color(.init(rgb: 0xF4EDE3))
    static let cardBackground = Color(.init(rgb: 0xE9D7C8))
    static let iconBackground = Color(.init(rgb: 0xDCC6B3))
    static let accent = Color(.init(rgb: 0x8A6348))
    static let border = Color(.init(rgb: 0x6D4A34))
    static let textPrimary = Color(.init(rgb: 0x2C2016))
    static let textSecondary = Color(.init(rgb: 0x4B3729))
}

struct PremiumView: View {
    @StateObject var storeManager = StoreManager()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Binding var showModal: Bool
    
    var body: some View {
        ZStack {
            PremiumPalette.appBackground
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
                            .foregroundColor(PremiumPalette.accent)
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
                            .foregroundColor(PremiumPalette.textSecondary)
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
                                    .foregroundColor(PremiumPalette.textSecondary)
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
        .foregroundColor(PremiumPalette.textPrimary)
    }
}

@available(iOS 13.0, *)
struct Header: View {
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Image(systemName: "crown")
                Image(systemName: "checkerboard.rectangle")
            }
            .font(.system(size: 36))
            .foregroundColor(PremiumPalette.accent)
            Text("Pro version".localized)
                .font(.largeTitle)
                .bold()
                .padding(.top, 8)
            Text("Chess: 2 Players".localized)
                .foregroundColor(PremiumPalette.textSecondary)
        }
        .padding(.vertical, 24)
    }
}


struct PremiumList: View {
    var items: [Feature] = [
        Feature(
            title: "No undo limits".localized,
            description: "Unlimited takebacks".localized,
            image: "arrow.uturn.left"
        ),
        Feature(
            title: "Chess clock".localized,
            description: "Play timed games with configurable clock control.".localized,
            image: "clock"
        ),
        Feature(
            title: "Puzzle configurator".localized,
            description: "Set up custom puzzle positions for training.".localized,
            image: "puzzlepiece"
        ),
        Feature(
            title: "Draggable pieces".localized,
            description: "Move pieces with fluid drag-and-drop interactions.".localized,
            image: "hand.draw"
        ),
        Feature(
            title: "More settings".localized,
            description: "Unlock additional board and gameplay preferences.".localized,
            image: "gearshape"
        ),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 10, content: {
            Text("Features")
                .font(.title2)
                .bold()
                .foregroundColor(PremiumPalette.textPrimary)
                .padding(.bottom, 2)

            ForEach(items) { item in
                FeatureListItem(title: item.title, description: item.description, image: item.image)
            }
        })
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(PremiumPalette.iconBackground.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PremiumPalette.border.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 10)
    }
    
    struct Feature: Identifiable {
        var id = UUID()
        var title: String
        var description: String
        var image: String
    }
}


struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumView(showModal: .constant(true))
    }
}
