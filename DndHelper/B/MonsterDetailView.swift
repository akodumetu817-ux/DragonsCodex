//
//  MonsterDetailView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI

@available(iOS 16.0, *)
struct MonsterDetailView: View {
    let monster: MonsterDetail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header (Image and Basic Info)
                MonsterDetailHeaderView(monster: monster)
                
                // MARK: - Core Stats
                MonsterCoreStatsView(monster: monster)

                // MARK: - Abilities (STR, DEX, etc.)
                MonsterAttributesView(monster: monster)
                
                // MARK: - Proficiencies & Senses
                Group {
                    MonsterProficienciesView(proficiencies: monster.proficiencies ?? [])
                    MonsterSensesView(senses: monster.senses)
                    MonsterLanguagesView(languages: monster.languages)
                }
                .padding(.horizontal)

                // MARK: - Immunities, Resistances, Vulnerabilities
                MonsterResistancesView(
                    vulnerabilities: monster.damage_vulnerabilities ?? [],
                    resistances: monster.damage_resistances ?? [],
                    immunities: monster.damage_immunities ?? [],
                    conditionImmunities: monster.condition_immunities ?? []
                )
                .padding(.horizontal)

                // MARK: - Special Abilities
                MonsterActionsSectionView(
                    title: "Special Abilities",
                    actions: monster.special_abilities ?? [],
                    isSpecialAbility: true
                )
                
                // MARK: - Actions
                MonsterActionsSectionView(
                    title: "Actions",
                    actions: monster.actions ?? []
                )

                // MARK: - Legendary Actions
                if let legendaryActions = monster.legendary_actions, !legendaryActions.isEmpty {
                    MonsterActionsSectionView(
                        title: "Legendary Actions",
                        actions: legendaryActions
                    )
                }
                
                Spacer()
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(monster.name ?? "Monster Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Subviews for MonsterDetailView

struct MonsterDetailHeaderView: View {
    let monster: MonsterDetail
    
    var body: some View {
        VStack {
            AsyncImage(url: monster.fullImageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 200)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 250)
                        .cornerRadius(10)
                        .padding(.horizontal)
                case .failure:
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.secondaryText)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(10)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top)

            Text(monster.name ?? "Unknown Monster")
                .font(.custom(AppFontName.aclonicaRegular, size: 28))
                .foregroundColor(.primaryText)
                .padding(.top, 8)

            Text("\(monster.size ?? "N/A Size") \(monster.type?.capitalized ?? "N/A Type"), \(monster.alignment?.capitalized ?? "N/A Alignment")")
                .font(.custom(AppFontName.aclonicaRegular, size: 16))
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Color.cardBackground.opacity(0.5)) // Легкий фон для хедера
    }
}

struct MonsterCoreStatsView: View {
    let monster: MonsterDetail

    private func formatChallengeRating(_ cr: Double?) -> String {
        guard let cr = cr else { return "N/A" }
        if cr == 0.125 { return "1/8" }
        if cr == 0.25 { return "1/4" }
        if cr == 0.5 { return "1/2" }
        return String(format: "%.0f (\(monster.xp ?? 0) XP)", cr)
    }
    
    private func getArmorClass(from acArray: [ArmorClassItem]?) -> String {
        guard let acArray = acArray, let firstAC = acArray.first else { return "N/A" }
        var acString = "\(firstAC.value)"
        if let type = firstAC.type, type != "natural" && type != "armor" {
             acString += " (\(type.capitalized))"
        }
        return acString
    }

    var body: some View {
        HStack(spacing: 0) {
            StatBlock(title: "Armor Class", value: getArmorClass(from: monster.armor_class))
            Divider().background(Color.secondaryText.opacity(0.5)).frame(height: 40)
            StatBlock(title: "Hit Points", value: "\(monster.hit_points ?? 0) (\(monster.hit_dice ?? "N/A"))")
            Divider().background(Color.secondaryText.opacity(0.5)).frame(height: 40)
            StatBlock(title: "Speed", value: monster.speed?.formattedDescription ?? "N/A")
        }
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
        
        HStack(spacing: 0) {
            StatBlock(title: "Challenge", value: formatChallengeRating(monster.challenge_rating))
            Divider().background(Color.secondaryText.opacity(0.5)).frame(height: 40)
             StatBlock(title: "Prof. Bonus", value: "+\(monster.proficiency_bonus ?? 0)")
        }
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct MonsterAttributesView: View {
    let monster: MonsterDetail
    
    private func modifier(for score: Int?) -> String {
        guard let score = score else { return "+0" }
        let mod = (score - 10) / 2
        return mod >= 0 ? "+\(mod)" : "\(mod)"
    }

    var body: some View {
        HStack(spacing: 0) {
            AttributeBlock(name: "STR", score: monster.strength, modifier: modifier(for: monster.strength))
            Divider().background(Color.secondaryText.opacity(0.5)).frame(maxHeight: .infinity)
            AttributeBlock(name: "DEX", score: monster.dexterity, modifier: modifier(for: monster.dexterity))
            Divider().background(Color.secondaryText.opacity(0.5)).frame(maxHeight: .infinity)
            AttributeBlock(name: "CON", score: monster.constitution, modifier: modifier(for: monster.constitution))
        }
        .frame(height: 70)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)

        HStack(spacing: 0) {
            AttributeBlock(name: "INT", score: monster.intelligence, modifier: modifier(for: monster.intelligence))
            Divider().background(Color.secondaryText.opacity(0.5)).frame(maxHeight: .infinity)
            AttributeBlock(name: "WIS", score: monster.wisdom, modifier: modifier(for: monster.wisdom))
            Divider().background(Color.secondaryText.opacity(0.5)).frame(maxHeight: .infinity)
            AttributeBlock(name: "CHA", score: monster.charisma, modifier: modifier(for: monster.charisma))
        }
        .frame(height: 70)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct MonsterProficienciesView: View {
    let proficiencies: [ProficiencyBonus]

    var body: some View {
        if !proficiencies.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Proficiencies")
                    .font(.custom(AppFontName.aclonicaRegular, size: 18))
                    .foregroundColor(Color.accentCol)
                ForEach(proficiencies, id: \.proficiency.index) { prof in
                    HStack {
                        Text(prof.proficiency.name.replacingOccurrences(of: "Saving Throw: ", with: "ST: ").replacingOccurrences(of: "Skill: ", with: ""))
                            .font(.custom(AppFontName.aclonicaRegular, size: 14))
                            .foregroundColor(.primaryText)
                        Spacer()
                        Text("+\(prof.value)")
                            .font(.custom(AppFontName.aclonicaRegular, size: 14))
                            .foregroundColor(.primaryText)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(10)
        }
    }
}

struct MonsterSensesView: View {
    let senses: Senses?

    var body: some View {
        if let senses = senses, senses.hasData {
            VStack(alignment: .leading, spacing: 8) {
                Text("Senses")
                    .font(.custom(AppFontName.aclonicaRegular, size: 18))
                    .foregroundColor(Color.accentCol)
                if let darkvision = senses.darkvision {
                    Text("Darkvision: \(darkvision)")
                        .font(.custom(AppFontName.aclonicaRegular, size: 14))
                        .foregroundColor(.primaryText)
                }
                if let passivePerception = senses.passive_perception {
                     Text("Passive Perception: \(passivePerception)")
                        .font(.custom(AppFontName.aclonicaRegular, size: 14))
                        .foregroundColor(.primaryText)
                }
                // Добавить другие чувства, если они есть в модели Senses
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(10)
        }
    }
}

struct MonsterLanguagesView: View {
    let languages: String?
    
    var body: some View {
        if let languages = languages, !languages.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Languages")
                    .font(.custom(AppFontName.aclonicaRegular, size: 18))
                    .foregroundColor(Color.accentCol)
                Text(languages)
                    .font(.custom(AppFontName.aclonicaRegular, size: 14))
                    .foregroundColor(.primaryText)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(10)
        }
    }
}



struct MonsterResistancesView: View {
    let vulnerabilities: [String]?
    let resistances: [String]?
    let immunities: [String]?
    let conditionImmunities: [ConditionReference]?

    @ViewBuilder func buildSection(title: String, items: [String]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.custom(AppFontName.aclonicaRegular, size: 14))
                    .foregroundColor(.secondaryText)
                Text(items.map { $0.capitalized }.joined(separator: ", "))
                    .font(.custom(AppFontName.aclonicaRegular, size: 14))
                    .foregroundColor(.primaryText)
            }
        }
    }
    
    @ViewBuilder func buildConditionSection(title: String, items: [ConditionReference]?) -> some View {
        if let items = items, !items.isEmpty {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.custom(AppFontName.aclonicaRegular, size: 14))
                    .foregroundColor(.secondaryText)
                Text(items.map { ($0.name ?? $0.index).capitalized }.joined(separator: ", "))
                    .font(.custom(AppFontName.aclonicaRegular, size: 14))
                    .foregroundColor(.primaryText)
            }
        }
    }

    var body: some View {
        let hasVulnerabilities = vulnerabilities?.isEmpty == false
        let hasResistances = resistances?.isEmpty == false
        let hasImmunities = immunities?.isEmpty == false
        let hasConditionImmunities = conditionImmunities?.isEmpty == false

        if hasVulnerabilities || hasResistances || hasImmunities || hasConditionImmunities {
            VStack(alignment: .leading, spacing: 10) {
                Text("Damage & Condition Traits")
                    .font(.custom(AppFontName.aclonicaRegular, size: 18))
                    .foregroundColor(Color.accentCol)
                
                buildSection(title: "Vulnerabilities", items: vulnerabilities ?? [])
                buildSection(title: "Resistances", items: resistances ?? [])
                buildSection(title: "Immunities", items: immunities ?? [])
                buildConditionSection(title: "Condition Immunities", items: conditionImmunities ?? [])
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(10)
        }
    }
}

struct MonsterActionsSectionView: View {
    let title: String
    let actions: [Action]
    var isSpecialAbility: Bool = false

    var body: some View {
        if !actions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.custom(AppFontName.aclonicaRegular, size: 20))
                    .foregroundColor(Color.accentCol)
                    .padding(.horizontal)

                ForEach(actions, id: \.name) { action in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(action.name)
                                .font(.custom(AppFontName.aclonicaRegular, size: 16))
                                .foregroundColor(.primaryText)
                            if let usage = action.usage {
                                Text("(\(usage.formattedDescription))")
                                   .font(.custom(AppFontName.aclonicaRegular, size: 12))
                                   .foregroundColor(.secondaryText)
                            }
                        }
                        Text(action.desc.replacingOccurrences(of: "_**", with: "**").replacingOccurrences(of: "**_", with: "**"))
                            .font(.custom(AppFontName.aclonicaRegular, size: 14))
                            .foregroundColor(.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let dc = action.dc {
                            Text("DC \(dc.dc_value) \(dc.dc_type.name) save. Success: \(dc.success_type).")
                                .font(.custom(AppFontName.aclonicaRegular, size: 13))
                                .foregroundColor(.secondaryText.opacity(0.8))
                        }
                        
                        if let damage = action.damage, !damage.isEmpty {
                            ForEach(damage, id: \.damage_dice_plus_type) { dmg in
                                Text("Damage: \(dmg.damage_dice ?? "") \(dmg.damage_type?.name ?? "")")
                                    .font(.custom(AppFontName.aclonicaRegular, size: 13))
                                    .foregroundColor(.secondaryText.opacity(0.8))
                            }
                        }

                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Helper Subviews for Stats etc.
struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title.uppercased())
                .font(.custom(AppFontName.aclonicaRegular, size: 10))
                .foregroundColor(.secondaryText)
            Text(value)
                .font(.custom(AppFontName.aclonicaRegular, size: 16))
                .foregroundColor(.primaryText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }
}

struct AttributeBlock: View {
    let name: String
    let score: Int?
    let modifier: String

    var body: some View {
        VStack {
            Text(name)
                .font(.custom(AppFontName.aclonicaRegular, size: 16))
                .foregroundColor(.accentCol)
            Text("\(score ?? 10)")
                .font(.custom(AppFontName.aclonicaRegular, size: 20))
                .foregroundColor(.primaryText)
            Text(modifier)
                .font(.custom(AppFontName.aclonicaRegular, size: 12))
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

