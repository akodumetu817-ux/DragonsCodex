//
//  BestiarySectionView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI

// MARK: - Bestiary Section (обновленный для передачи isLoading и errorMessage)
struct BestiarySectionView: View {
    let monsters: [MonsterDetail]
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bestiary")
                    .font(.custom(AppFontName.aclonicaRegular, size: 20))
                    .foregroundColor(.primaryText)
                Spacer()
                if #available(iOS 16.0, *) {
                    NavigationLink(destination: AllMonstersView()) {
                        Text("View All >")
                            .font(.custom(AppFontName.aclonicaRegular, size: 14))
                            .foregroundColor(Color.accentCol)
                    }
                } else {
                    // Fallback on earlier versions
                }
            }

            if isLoading && monsters.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical)
            } else if let msg = errorMessage, monsters.isEmpty {
                Text(msg).font(.custom(AppFontName.aclonicaRegular, size: 14)).foregroundColor(.levelRed)
                    .frame(maxWidth: .infinity, alignment: .center).padding()
            } else if monsters.isEmpty {
                 Text("No popular monsters loaded yet.")
                    .font(.custom(AppFontName.aclonicaRegular, size: 14)).foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center).padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(monsters) { monster in
                        if #available(iOS 16.0, *) {
                            NavigationLink(destination: MonsterDetailView(monster: monster)) {
                                MonsterCardView(monster: monster)
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
