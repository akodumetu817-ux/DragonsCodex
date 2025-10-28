//
//  RealmModel.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import Foundation
import RealmSwift

class CharacterObject: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var name: String = ""
    @Persisted var race: String = ""
    @Persisted var className: String = ""
    @Persisted var level: Int = 1
    
    @Persisted var avatarImageType: AvatarImageType = .placeholder
    @Persisted var avatarAssetName: String? = nil
    @Persisted var avatarData: Data? = nil
    
    @Persisted var status: CharacterStatus = .inactive

    @Persisted var strength: Int = 10
    @Persisted var dexterity: Int = 10
    @Persisted var constitution: Int = 10
    @Persisted var intelligence: Int = 10
    @Persisted var wisdom: Int = 10
    @Persisted var charisma: Int = 10
    
    @Persisted var currentHP: Int = 10
    @Persisted var maxHP: Int = 10
    
    @Persisted var inventoryItems = List<InventoryItemObject>()
    
    convenience init(name: String, race: String, className: String, level: Int = 1,
                     strength: Int = 10, dexterity: Int = 10, constitution: Int = 10,
                     intelligence: Int = 10, wisdom: Int = 10, charisma: Int = 10,
                     currentHP: Int = 10, maxHP: Int = 10) {
        self.init()
        self.name = name
        self.race = race
        self.className = className
        self.level = level
        self.strength = strength
        self.dexterity = dexterity
        self.constitution = constitution
        self.intelligence = intelligence
        self.wisdom = wisdom
        self.charisma = charisma
        self.currentHP = currentHP
        self.maxHP = maxHP
    }
}

enum AvatarImageType: String, PersistableEnum {
    case placeholder
    case template
    case customFromGalleryOrCamera
}

enum CharacterStatus: String, PersistableEnum {
    case active
    case inactive
}

class InventoryItemObject: EmbeddedObject, ObjectKeyIdentifiable {
    @Persisted var id: ObjectId = ObjectId.generate()
    @Persisted var itemName: String = ""
    @Persisted var itemDescription: String? = nil
    @Persisted var quantity: Int = 1
    @Persisted var isEquipped: Bool = false
    
}

