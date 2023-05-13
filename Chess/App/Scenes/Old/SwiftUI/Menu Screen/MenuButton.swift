//
//  MenuButton.swift
//  Chess
//
//  Created by exerhythm on 9/30/21.
//

import SwiftUI

@available(iOS 13.0, *)
struct MenuButton: View {
    var image: String
    var text: String
    
    var body: some View {
        HStack(spacing:10) {
            Image(systemName: image)
            Text(text)
                .font(.system(size: 17))
                .fontWeight(.medium)
        }
        .frame(maxWidth:330)
        .padding(20)
        .font(.system(size: 19))
        .foregroundColor(.black)
        .background(Color.black.opacity(0.075))
        
        .cornerRadius(20)
        
    }
}

@available(iOS 13.0, *)
struct MenuButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(red: 0.9190433025, green: 0.8973273635, blue: 0.8671943545)
                .edgesIgnoringSafeArea(.all)
            MenuButton(image: "globe", text: "Online game")
        }
    }
}
