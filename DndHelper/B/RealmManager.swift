//
//  RealmManager.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//


import Foundation
import RealmSwift

class RealmManager: ObservableObject {
    static let shared = RealmManager()
    private var realm: Realm?

    private init() {
        do {
            let config = Realm.Configuration(
                schemaVersion: 1,
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 1 {
                    }
                }
            )
            Realm.Configuration.defaultConfiguration = config
            realm = try Realm()
            print("Realm initialized successfully. Path: \(realm?.configuration.fileURL?.absoluteString ?? "N/A")")
        } catch {
            print("Error initializing Realm: \(error)")
        }
    }

    // MARK: - Character Operations
    
    func addCharacter(_ character: CharacterObject) {
        guard let realm = realm else { return }
        do {
            try realm.write {
                realm.add(character)
            }
            print("Character '\(character.name)' added successfully.")
        } catch {
            print("Error adding character: \(error)")
        }
    }

    func fetchCharacters() -> Results<CharacterObject>? {
        return realm?.objects(CharacterObject.self).sorted(byKeyPath: "name", ascending: true)
    }
    
    func updateCharacter(id: ObjectId, updateBlock: @escaping (CharacterObject) -> Void) {
        guard let realm = realm else { return }
        guard let characterToUpdate = realm.object(ofType: CharacterObject.self, forPrimaryKey: id) else {
            print("Character with id \(id) not found for update.")
            return
        }
        
        do {
            try realm.write {
                updateBlock(characterToUpdate)
            }
            
            if !characterToUpdate.isInvalidated {
                 print("Character '\(characterToUpdate.name)' updated successfully.")
            }
        } catch {
            print("Error updating character \(id): \(error)")
        }
    }

    func updateCharacterName(id: ObjectId, newName: String) {
        updateCharacter(id: id) { character in
            character.name = newName
        }
    }

    func deleteCharacter(id: ObjectId) {
        guard let realm = realm else { return }
        guard let characterToDelete = realm.object(ofType: CharacterObject.self, forPrimaryKey: id) else {
            print("Character with id \(id) not found for deletion.")
            return
        }
        do {
            try realm.write {
                realm.delete(characterToDelete)
            }
            print("Character with id \(id) (was named '\(characterToDelete.name)') deleted successfully.")
        } catch {
            print("Error deleting character \(id): \(error)")
        }
    }
    
    // MARK: - Inventory Operations
    
    func addItemToCharacter(characterId: ObjectId, itemName: String, quantity: Int = 1, description: String? = nil) {
        updateCharacter(id: characterId) { character in
            let newItem = InventoryItemObject()
            newItem.itemName = itemName
            newItem.quantity = quantity
            newItem.itemDescription = description
            character.inventoryItems.append(newItem)
        }
    }
    
    func updateItemInCharacter(characterId: ObjectId, itemId: ObjectId, updateBlock: @escaping (InventoryItemObject) -> Void) {
         updateCharacter(id: characterId) { character in
            if let itemToUpdate = character.inventoryItems.first(where: { $0.id == itemId }) {
                updateBlock(itemToUpdate)
            } else {
                print("Item with id \(itemId) not found in character \(character.name)")
            }
        }
    }
    
    func removeItemFromCharacter(characterId: ObjectId, itemId: ObjectId) {
        updateCharacter(id: characterId) { character in
            if let index = character.inventoryItems.firstIndex(where: { $0.id == itemId }) {
                character.inventoryItems.remove(at: index)
            } else {
                 print("Item with id \(itemId) not found for removal in character \(character.name).")
            }
        }
    }
}
