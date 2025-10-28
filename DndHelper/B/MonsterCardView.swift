//
//  MonsterCardView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI

import SwiftUI

struct MonsterCardView: View {
    let monster: MonsterDetail

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: monster.fullImageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.secondaryText)
                        .padding(5)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)


            VStack(alignment: .leading, spacing: 4) {
                Text(monster.name ?? "Unknown Monster")
                    .font(.custom(AppFontName.aclonicaRegular, size: 16))
                    .foregroundColor(.primaryText)
                    .lineLimit(1)
                Text(monster.type?.capitalized ?? "Unknown Type")
                    .font(.custom(AppFontName.aclonicaRegular, size: 12))
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            
            if let cr = monster.challenge_rating {
                Text("CR \(formatChallengeRating(cr))")
                    .font(.custom(AppFontName.aclonicaRegular, size: 10))
                    .foregroundColor(Color.buttonTextOnYellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelColor(for: cr))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(10)
    }

    private func formatChallengeRating(_ cr: Double) -> String {
        if cr == 0.125 { return "1/8" }
        if cr == 0.25 { return "1/4" }
        if cr == 0.5 { return "1/2" }
        return String(format: "%.0f", cr)
    }
    
    private func levelColor(for cr: Double) -> Color {
        switch cr {
        case 0...0.25: return .levelBlue
        case 0.5...2: return .levelGreen
        case 3...5: return .levelYellowOrange
        case 6...10: return .levelOrange
        case 11...16: return .levelRed
        default: return .levelPurple
        }
    }
}
