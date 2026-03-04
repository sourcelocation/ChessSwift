//
//  FeatureListItem.swift
//  Chess
//
//  Created by exerhythm on 7/27/21.
//

import SwiftUI


struct FeatureListItem: View {
    var title: String
    var description: String
    var image: String
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PremiumPalette.iconBackground)
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName:image)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(PremiumPalette.accent)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(PremiumPalette.textPrimary)
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(PremiumPalette.textSecondary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(PremiumPalette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PremiumPalette.border.opacity(0.14), lineWidth: 1)
        )
    }
}


struct FeatureListItem_Previews: PreviewProvider {
    static var previews: some View {
        FeatureListItem(
            title: "Puzzle configurator".localized,
            description: "Build custom puzzles quickly from any position.".localized,
            image: "puzzlepiece"
        )
            .previewLayout(.sizeThatFits)
            .frame(width: 400, alignment: .center)
    }
}
