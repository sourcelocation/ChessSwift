//
//  FeatureListItem.swift
//  Chess
//
//  Created by exerhythm on 7/27/21.
//

import SwiftUI


struct FeatureListItem: View {
    var title: String
    var image: String
    
    var body: some View {
        HStack {
            Image(systemName:image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: image == "puzzlepiece" ? 30 : 22, height: 22)
                .foregroundColor(.accentColor)
                .padding(.leading, image == "puzzlepiece" ? -8 : 0)
            Text(title)
                .font(.system(size: 18))
                .fontWeight(.medium)
                .padding(.leading, 6)
        }
    }
}


struct FeatureListItem_Previews: PreviewProvider {
    static var previews: some View {
        FeatureListItem(title: "Puzzle configurator".localized, image: "puzzlepiece")
            .previewLayout(.sizeThatFits)
            .frame(width: 400, height: 64, alignment: .center)
    }
}
