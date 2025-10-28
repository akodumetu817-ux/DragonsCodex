//
//  Model.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import Foundation

import Foundation

struct MonsterListResponse: Codable {
    let count: Int?
    let results: [MonsterListItem]?
}

struct MonsterListItem: Codable, Identifiable {
    var id: String { index } // Используем index как id, т.к. он уникален
    let index: String
    let name: String?
    let url: String? // Относительный URL
}


struct MonsterDetail: Codable, Identifiable {
    var id: String { index }
    let index: String
    let name: String?
    let desc: String? // Общее описание, если есть
    let size: String?
    let type: String?
    let subtype: String? // Иногда есть подтип
    let alignment: String?
    let armor_class: [ArmorClassItem]? // Уже есть
    let hit_points: Int?
    let hit_dice: String?
    let hit_points_roll: String? // e.g. "18d10+36"
    
    let speed: Speed?
    
    let strength: Int?
    let dexterity: Int?
    let constitution: Int?
    let intelligence: Int?
    let wisdom: Int?
    let charisma: Int?
    
    let proficiencies: [ProficiencyBonus]?
    
    let damage_vulnerabilities: [String]? // <--- ИЗМЕНЕНИЕ: было [DamageTypeReference]?
        let damage_resistances: [String]?   // <--- ИЗМЕНЕНИЕ: было [DamageTypeReference]?
        let damage_immunities: [String]?    // <--- ИЗМЕНЕНИЕ: было [DamageTypeReference]?
        let condition_immunities: [ConditionReference]?
    
    let senses: Senses?
    let languages: String?
    
    let challenge_rating: Double?
    let proficiency_bonus: Int?
    let xp: Int?
    
    let special_abilities: [Action]? // Структура похожа на Action
    let actions: [Action]?
    let legendary_actions: [Action]?
    // let reactions: [Action]? // Если нужно будет добавить

    let image: String?
    var fullImageURL: URL? {
        guard let imagePath = image else { return nil }
        return URL(string: AppConstants.dndAPIBaseURL + imagePath)
    }

    // Для превью
    static var sampleAboleth: MonsterDetail {
            return MonsterDetail(
                index: "aboleth", name: "Aboleth", desc: "An aboleth is a باولاو, lawful evil, fish-like amphibian of great size.",
                size: "Large", type: "aberration", subtype: nil, alignment: "lawful evil",
                armor_class: [ArmorClassItem(type: "natural", value: 17)],
                hit_points: 135, hit_dice: "18d10", hit_points_roll: "18d10+36",
                speed: Speed(walk: "1", swim: "2", fly: "3", burrow: "4", climb: "5"),
                strength: 21, dexterity: 9, constitution: 15, intelligence: 18, wisdom: 15, charisma: 18,
                proficiencies: [
                    ProficiencyBonus(value: 6, proficiency: ProficiencyReference(index: "saving-throw-con", name: "Saving Throw: CON", url: "")),
                    ProficiencyBonus(value: 12, proficiency: ProficiencyReference(index: "skill-history", name: "Skill: History", url: "")),
                ],
                damage_vulnerabilities: [], // Теперь массив строк
                damage_resistances: ["cold", "fire"], // Пример массива строк
                damage_immunities: ["poison"],   // Пример массива строк
                condition_immunities: [ConditionReference(index: "charmed", name: "Charmed", url: "")], // Остается массивом объектов
                senses: Senses(darkvision: "120 ft.", passive_perception: 20),
                languages: "Deep Speech, telepathy 120 ft.",
                challenge_rating: 10, proficiency_bonus: 4, xp: 5900,
                special_abilities: [
                    Action(name: "Amphibious", desc: "The aboleth can breathe air and water.", attack_bonus: nil, damage: nil, dc: nil, usage: nil),
                    Action(name: "Mucous Cloud", desc: "While underwater, the aboleth is surrounded by transformative mucus...", attack_bonus: nil, damage: nil, dc: nil, usage: nil)
                ],
                actions: [
                    Action(name: "Multiattack", desc: "The aboleth makes three tentacle attacks.", attack_bonus: nil, damage: nil, dc: nil, usage: nil),
                    Action(name: "Tentacle", desc: "Melee Weapon Attack: +9 to hit, reach 10 ft., one target. Hit: 12 (2d6 + 5) bludgeoning damage...", attack_bonus: 9, damage: [Damage(damage_type: DamageTypeReference(index: "bludgeoning", name: "Bludgeoning", url: ""), damage_dice: "2d6+5")], dc: nil, usage: nil)
                ],
                legendary_actions: [
                    Action(name: "Detect", desc: "The aboleth makes a Wisdom (Perception) check.", attack_bonus: nil, damage: nil, dc: nil, usage: nil)
                ],
                image: "/api/images/monsters/aboleth.png"
            )
        }
}

struct ArmorClassItem: Codable {
    let type: String?
    let value: Int
    // let desc: String? // Иногда есть описание
}

struct Speed: Codable {
    let walk: String?
    let swim: String?
    let fly: String?
    let burrow: String?
    let climb: String?
    // hover: Bool?

    var formattedDescription: String {
        var parts: [String] = []
        if let walk = walk { parts.append("Walk \(walk)") }
        if let fly = fly { parts.append("Fly \(fly)") }
        if let swim = swim { parts.append("Swim \(swim)") }
        if let burrow = burrow { parts.append("Burrow \(burrow)") }
        if let climb = climb { parts.append("Climb \(climb)") }
        return parts.isEmpty ? "N/A" : parts.joined(separator: ", ")
    }
}

struct ProficiencyBonus: Codable {
    let value: Int
    let proficiency: ProficiencyReference
}

struct ProficiencyReference: Codable {
    let index: String
    let name: String
    let url: String
}

struct DamageTypeReference: Codable, Hashable { // Hashable для ForEach
    let index: String
    let name: String?
    let url: String?
}

struct ConditionReference: Codable, Hashable { // Hashable для ForEach
    let index: String
    let name: String?
    let url: String?
}

struct Senses: Codable {
    let darkvision: String?
    let passive_perception: Int?
    // Могут быть и другие, например: blindsight, tremorsense, truesight
    var hasData: Bool {
        darkvision != nil || passive_perception != nil
    }
}

struct Action: Codable { // Также используется для SpecialAbility и LegendaryAction
    let name: String
    let desc: String
    let attack_bonus: Int?
    let damage: [Damage]?
    let dc: DC? // Difficulty Class
    let usage: ActionUsage?
    // multiattack_type: String?, actions: [ActionNameCount]? // Для Multiattack
}

struct Damage: Codable, Hashable { // Hashable для ForEach, если нужен id
    static func == (lhs: Damage, rhs: Damage) -> Bool {
        return lhs.damage_dice == rhs.damage_dice && lhs.damage_type?.index == rhs.damage_type?.index
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(damage_dice)
        hasher.combine(damage_type?.index)
    }
    
    let damage_type: DamageTypeReference?
    let damage_dice: String?
    // let choose: Int? // Для выбора вариантов урона
    // let dc: DC? // Иногда урон связан с DC
    
    var damage_dice_plus_type: String { // Уникальный идентификатор для ForEach, если damage_dice и type не уникальны сами по себе
        "\(damage_dice ?? "")_\(damage_type?.index ?? UUID().uuidString)"
    }
}

struct DC: Codable {
    let dc_type: DCType
    let dc_value: Int
    let success_type: String // e.g., "none", "half"
}

struct DCType: Codable {
    let index: String
    let name: String // e.g., "STR", "DEX"
    let url: String
}

struct ActionUsage: Codable {
    let type: String // e.g., "per day", "recharge on roll"
    let times: Int? // For "per day"
    let dice: String? // For "recharge on roll"
    let min_value: Int? // For "recharge on roll"
    
    var formattedDescription: String {
        var desc = type.capitalized
        if let times = times, type == "per day" {
            desc += " (\(times))"
        } else if let dice = dice, let min_value = min_value, type.contains("recharge") {
            desc += " (Recharge \(min_value)–\(dice.suffix(1)))" // Предполагаем формат d6, d8 и т.д.
        }
        return desc
    }
}
