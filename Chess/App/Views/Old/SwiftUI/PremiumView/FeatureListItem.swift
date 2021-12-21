//
//  FeatureListItem.swift
//  Chess
//
//  Created by exerhythm on 7/27/21.
//

import SwiftUI

@available(iOS 13.0.0, *)
struct FeatureListItem: View {
    var title: String
    var image: String
    
    var body: some View {
        HStack {
            Image(systemName:image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: image == "puzzlepiece" ? 38 : 28, height: 28)
                .foregroundColor(.accentColor)
                .padding(.leading,image == "puzzlepiece" ? -8 : 0)
            Text(title)
                .font(.system(size: 18))
                .fontWeight(.medium)
                .padding(.leading, 6)
        }
    }
}

@available(iOS 13.0.0, *)
struct FeatureListItem_Previews: PreviewProvider {
    static var previews: some View {
        FeatureListItem(title: "Puzzle configurator", image: "puzzlepiece")
            .previewLayout(.sizeThatFits)
            .frame(width: 400, height: 64, alignment: .center)
    }
}
