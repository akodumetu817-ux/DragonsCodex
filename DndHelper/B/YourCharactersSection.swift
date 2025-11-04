//
//  CharactersSectionView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI

// MARK: - Your Characters Section (обновленный)
struct YourCharactersSection: View {
    let characters: [CharacterObject]
    var onAddCharacter: () -> Void
    var onDelete: (IndexSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Characters")
                    .font(.custom(AppFontName.aclonicaRegular, size: 20))
                    .foregroundColor(.primaryText)
                Spacer()
                Button(action: onAddCharacter) {
                    Text("+ Create Character")
                        .font(.custom(AppFontName.aclonicaRegular, size: 14))
                        .foregroundColor(Color.buttonTextOnYellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentCol)
                        .cornerRadius(8)
                }
            }

            if characters.isEmpty {
                Text("No characters yet. Tap '+' to create one!")
                    .font(.custom(AppFontName.aclonicaRegular, size: 14))
                    .foregroundColor(.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.cardBackground.opacity(0.5))
                    .cornerRadius(10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(characters) { character in
                            if #available(iOS 16.0, *) {
                                NavigationLink(destination: CharacterDetailView(characterId: character.id)) {
                                    CharacterHomeCardView(character: character)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Fallback on earlier versions
                            }
                        }
                    }
                }
            }
        }
    }
}
