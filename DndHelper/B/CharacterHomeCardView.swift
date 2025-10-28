//
//  CharacterCardView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI
import RealmSwift

// MARK: - Character Card View for Home Screen (обновленный)
struct CharacterHomeCardView: View {
    @ObservedRealmObject var character: CharacterObject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                switch character.avatarImageType {
                case .customFromGalleryOrCamera:
                    if let imageData = character.avatarData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable().aspectRatio(contentMode: .fill)
                    } else {
                        defaultAvatarImage
                    }
                case .template:
                    if let assetName = character.avatarAssetName, !assetName.isEmpty {
                        Image(assetName)
                            .resizable().aspectRatio(contentMode: .fill)
                            .offset(y: 20)
                    } else {
                        defaultAvatarImage
                    }
                case .placeholder:
                    defaultAvatarImage
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.3))
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.custom(AppFontName.aclonicaRegular, size: 18))
                    .foregroundColor(Color.primaryText)
                    .lineLimit(1)
                Text("\(character.race) / \(character.className)")
                    .font(.custom(AppFontName.aclonicaRegular, size: 12))
                    .foregroundColor(Color.secondaryText)
                    .lineLimit(1)
                Text("Lvl \(character.level)")
                    .font(.custom(AppFontName.aclonicaRegular, size: 10))
                    .foregroundColor(Color.accentCol)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.cardBackground)
        .cornerRadius(15)
        .frame(width: 170)
    }
    
    private var defaultAvatarImage: some View {
        Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(Color.secondaryText)
            .padding(30)
    }
}


