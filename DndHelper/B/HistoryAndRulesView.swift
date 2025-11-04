//
//  LoreView.swift
//  Melbe
//
//  Created by D K on 09.05.2025.
//

import SwiftUI

#Preview {
    HistoryAndRulesView()
}


struct HistoryAndRulesView: View {
    private let fontName = "Aclonica-Regular"
    private let screenBackgroundColor = Color.appBackground
    private let cardBackgroundColor = Color(hex: "343a40")
    private let accentColor = Color(hex: "0075a5")
    private let textColor = Color(hex: "e9ecef")
    private let secondaryTextColor = Color(hex: "adb5bd")
    
    
    @State private var isShown = false
    
    struct AbilityScoreInfo: Identifiable {
        let id = UUID()
        let name: String
        let abbreviation: String
        let description: String
    }
    
    let abilityScores: [AbilityScoreInfo] = [
        AbilityScoreInfo(name: "Strength", abbreviation: "STR", description: "Physical power, carrying capacity, melee attacks, lifting, pushing, breaking things."),
        AbilityScoreInfo(name: "Dexterity", abbreviation: "DEX", description: "Agility, reflexes, balance, ranged attacks, stealth, picking locks."),
        AbilityScoreInfo(name: "Constitution", abbreviation: "CON", description: "Endurance, stamina, health points, resisting poison and disease."),
        AbilityScoreInfo(name: "Intelligence", abbreviation: "INT", description: "Memory, reasoning, spellcasting for wizards, investigation, knowledge skills."),
        AbilityScoreInfo(name: "Wisdom", abbreviation: "WIS", description: "Perception, intuition, insight, willpower, survival, spellcasting for clerics and druids."),
        AbilityScoreInfo(name: "Charisma", abbreviation: "CHA", description: "Force of personality, leadership, persuasion, deception, spellcasting for sorcerers and bards.")
    ]
    
    struct CharacterCreationStep: Identifiable {
        let id: Int
        let title: String
        let description: String
    }
    
    let creationSteps: [CharacterCreationStep] = [
        CharacterCreationStep(id: 1, title: "Choose a Race", description: "Determines your character's appearance, some starting ability scores, and unique racial traits."),
        CharacterCreationStep(id: 2, title: "Choose a Class", description: "Defines your character's primary abilities, skills, and role in an adventuring party (e.g., Fighter, Wizard)."),
        CharacterCreationStep(id: 3, title: "Determine Ability Scores", description: "Roll dice (typically 4d6, drop lowest, for each of 6 scores) or use a point-buy system to set STR, DEX, CON, INT, WIS, CHA."),
        CharacterCreationStep(id: 4, title: "Choose Background", description: "Describes your character's history, occupation, and provides additional skills, proficiencies, and starting equipment."),
        CharacterCreationStep(id: 5, title: "Choose Equipment", description: "Select weapons, armor, adventuring gear, and other items based on your class and background choices.")
    ]
    
    struct PlayExampleEntry: Identifiable {
        let id = UUID()
        let speaker: String
        let dialogue: String
        var speakerColor: Color {
            speaker == "DM" ? Color.red : Color.green
        }
    }
    
    let playExamples: [PlayExampleEntry] = [
        PlayExampleEntry(speaker: "DM", dialogue: "A goblin leaps from behind the rocks! Roll for initiative."),
        PlayExampleEntry(speaker: "Player", dialogue: "I roll a 15 plus my DEX modifier of +2, so 17 total."),
        PlayExampleEntry(speaker: "DM", dialogue: "You go first. What do you do?")
    ]
    
    var body: some View {
        ZStack {
            screenBackgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                NewHeaderView(title: "History & Rules", description: "Discover the history and rules.")
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        RulesSectionCard(title: "The Basics", accentColor: accentColor, cardBackgroundColor: cardBackgroundColor, textColor: textColor, secondaryTextColor: secondaryTextColor, fontName: fontName) {
                            Text("Dungeons & Dragons 5th Edition is a tabletop roleplaying game where players create characters and embark on adventures guided by a Dungeon Master (DM). The core mechanic involves rolling a 20-sided die (d20) and adding modifiers (from ability scores, proficiency, etc.) to meet or exceed a target number (Difficulty Class or DC) set by the DM or by game rules.")
                                .font(Font.custom(fontName, size: 14))
                                .lineSpacing(5)
                        }
                        
                        RulesSectionCard(title: "Ability Scores", accentColor: accentColor, cardBackgroundColor: cardBackgroundColor, textColor: textColor, secondaryTextColor: secondaryTextColor, fontName: fontName) {
                            Text("These six scores define your character's raw talent and capabilities. Each score typically ranges from 3 to 20 for player characters (higher for powerful monsters) and provides a modifier used in many dice rolls (+1 for every 2 points above 10, -1 for every 2 points below 10).")
                                .font(Font.custom(fontName, size: 14))
                                .padding(.bottom, 10)
                            
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)], spacing: 15) {
                                ForEach(abilityScores) { score in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(score.name) (\(score.abbreviation))")
                                            .font(Font.custom(fontName, size: 15).bold())
                                            .foregroundColor(textColor)
                                        Text(score.description)
                                            .font(Font.custom(fontName, size: 12))
                                            .foregroundColor(secondaryTextColor)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 150)
                                    .background(cardBackgroundColor.brightness(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        RulesSectionCard(title: "Dice & Checks", accentColor: accentColor, cardBackgroundColor: cardBackgroundColor, textColor: textColor, secondaryTextColor: secondaryTextColor, fontName: fontName) {
                            HStack(spacing: 8) {
                                ForEach(["d4", "d6", "d8", "d10"], id: \.self) { dieName in
                                    Text(dieName)
                                        .font(Font.custom(fontName, size: 12))
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(cardBackgroundColor.brightness(0.1))
                                        .cornerRadius(6)
                                }
                                Spacer()
                            }
                            .padding(.bottom, 10)
                            
                            Text("Most important actions are resolved by rolling a d20 and adding relevant modifiers. This applies to:")
                                .font(Font.custom(fontName, size: 14))
                                .padding(.bottom, 5)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                CheckTypeItem(text: "Ability Checks: Used for tasks like climbing, persuading, or recalling lore (d20 + ability modifier + proficiency bonus if applicable).", accentColor: accentColor, fontName: fontName)
                                CheckTypeItem(text: "Attack Rolls: Used to hit an opponent in combat (d20 + ability modifier + proficiency bonus + other bonuses vs. Armor Class).", accentColor: accentColor, fontName: fontName)
                                CheckTypeItem(text: "Saving Throws: Used to resist spells, traps, or other harmful effects (d20 + ability modifier + proficiency bonus if applicable vs. a Spell Save DC or effect DC).", accentColor: accentColor, fontName: fontName)
                            }
                        }
                        
                        RulesSectionCard(title: "Character Creation", accentColor: accentColor, cardBackgroundColor: cardBackgroundColor, textColor: textColor, secondaryTextColor: secondaryTextColor, fontName: fontName) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(creationSteps) { step in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text("\(step.id)")
                                            .font(Font.custom(fontName, size: 14).bold())
                                            .foregroundColor(cardBackgroundColor.opacity(0.5))
                                            .frame(width: 24, height: 24)
                                            .background(accentColor)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(step.title)
                                                .font(Font.custom(fontName, size: 15).bold())
                                                .foregroundColor(textColor)
                                            Text(step.description)
                                                .font(Font.custom(fontName, size: 12))
                                                .foregroundColor(secondaryTextColor)
                                        }
                                    }
                                }
                            }
                            
                            Button {
                                isShown.toggle()
                            } label: {
                                Text("Create Character")
                                    .font(Font.custom(fontName, size: 16))
                                    
                            }
                            .foregroundColor(cardBackgroundColor)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(accentColor)
                            .cornerRadius(8)
                            .padding(.top, 10)

                        
                        }
                        
                        RulesSectionCard(title: "Example of Play", accentColor: accentColor, cardBackgroundColor: cardBackgroundColor, textColor: textColor, secondaryTextColor: secondaryTextColor, fontName: fontName) {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(playExamples) { example in
                                    HStack(alignment: .top) {
                                        Text("\(example.speaker):")
                                            .font(Font.custom(fontName, size: 14).bold())
                                            .foregroundColor(example.speakerColor)
                                            .frame(width: example.speaker == "Player" ? 60 : 40, alignment: .leading)
                                        Text(example.dialogue)
                                            .font(Font.custom(fontName, size: 14))
                                            .foregroundColor(textColor)
                                    }
                                    .padding(10)
                                    .background(cardBackgroundColor.brightness(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        
                    }
                    .padding()
                }
            }
        }
        .foregroundColor(textColor)
        .sheet(isPresented: $isShown) {
            if #available(iOS 16.0, *) {
                AddCharacterView()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

struct RulesSectionCard<Content: View>: View {
    let title: String
    let accentColor: Color
    let cardBackgroundColor: Color
    let textColor: Color
    let secondaryTextColor: Color
    let fontName: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Font.custom(fontName, size: 18).bold())
                .foregroundColor(accentColor)
                .padding(.bottom, 5)
            content
                .foregroundColor(textColor)
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct CheckTypeItem: View {
    let text: String
    let accentColor: Color
    let fontName: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(accentColor)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
            Text(text)
                .font(Font.custom(fontName, size: 13))
                .lineSpacing(4)
        }
    }
}

