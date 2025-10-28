//
//  CharacterDetailViewModel.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI
import Combine
import RealmSwift

@MainActor
class CharacterDetailViewModel: ObservableObject {
    @ObservedRealmObject var character: CharacterObject // Наблюдаем за объектом Realm
    
    // Локальные копии для редактирования, чтобы не писать в Realm на каждое изменение TextField
    // Они будут синхронизироваться с character при входе в режим редактирования и при сохранении.
    @Published var editableName: String
    @Published var editableRace: String
    @Published var editableClassName: String
    @Published var editableLevel: Int
    
    @Published var editableStrength: Int
    @Published var editableDexterity: Int
    @Published var editableConstitution: Int
    @Published var editableIntelligence: Int
    @Published var editableWisdom: Int
    @Published var editableCharisma: Int
    
    @Published var editableCurrentHP: Int
    @Published var editableMaxHP: Int
    
    // Для инвентаря
    @Published var inventoryItems: [InventoryItemObject] // Локальная копия для отображения/редактирования
    @Published var newItemName: String = "" // Для добавления нового предмета
    
    @Published var isEditing: Bool = false // Режим редактирования
    @Published var showingAddItemAlert: Bool = false // Или sheet для добавления предмета
    
    // Для выбора аватара при редактировании
    @Published var selectedAvatarTypeDuringEdit: AvatarImageType
    @Published var selectedTemplateAssetNameDuringEdit: String?
    @Published var customAvatarImageDuringEdit: Image?
    private var customAvatarDataDuringEdit: Data?

    @Published var showingImagePickerSheet: Bool = false
    @Published var showingPhotoPicker: Bool = false
    @Published var showingCamera: Bool = false
    
    let templateAvatars: [String: String] // Такие же, как в AddCharacterViewModel
    
    private var notificationToken: NotificationToken?

    init(characterId: ObjectId) {
        // Загружаем персонажа из Realm
        // Это может быть небезопасно, если объект не будет найден.
        // Лучше передавать CharacterObject напрямую, если он уже загружен.
        // Но для NavigationLink с ID это типичный подход.
        guard let realm = try? Realm(),
              let char = realm.object(ofType: CharacterObject.self, forPrimaryKey: characterId) else {
            // Обработка случая, когда персонаж не найден (например, выбросить ошибку или установить флаг)
            // Сейчас это приведет к крашу, если char будет nil.
            // Для простоты пока предполагаем, что персонаж всегда существует.
            // В реальном приложении здесь нужна надежная обработка.
            fatalError("Character with ID \(characterId) not found.")
        }
        self.character = char
        
        // Инициализация редактируемых полей
        self.editableName = char.name
        self.editableRace = char.race
        self.editableClassName = char.className
        self.editableLevel = char.level
        
        self.editableStrength = char.strength
        self.editableDexterity = char.dexterity
        self.editableConstitution = char.constitution
        self.editableIntelligence = char.intelligence
        self.editableWisdom = char.wisdom
        self.editableCharisma = char.charisma
        
        self.editableCurrentHP = char.currentHP
        self.editableMaxHP = char.maxHP
        
        self.inventoryItems = Array(char.inventoryItems)

        self.selectedAvatarTypeDuringEdit = char.avatarImageType
        self.selectedTemplateAssetNameDuringEdit = char.avatarAssetName
        if char.avatarImageType == .customFromGalleryOrCamera, let data = char.avatarData, let uiImage = UIImage(data: data) {
            self.customAvatarImageDuringEdit = Image(uiImage: uiImage)
            self.customAvatarDataDuringEdit = data
        }
        
        // Примерный список шаблонов (скопируй из AddCharacterViewModel)
        self.templateAvatars = [
            "template_fighter": "Fighter", "template_wizard": "Wizard", "template_rogue": "Rogue",
            "barbarian_m": "Barbarian", "bard_f": "Bard",
        ]
        
        // Наблюдаем за изменениями в character, если они приходят из другого места
        notificationToken = char.observe { [weak self] change in
            guard let self = self else { return }
            switch change {
            case .change(let object, let properties):
                print("CharacterDetailVM: Character \(object) changed properties: \(properties.map(\.name))")
                if !self.isEditing { // Обновляем редактируемые поля, только если не в режиме редактирования
                    self.syncEditableFieldsFromCharacter()
                }
            case .deleted:
                print("CharacterDetailVM: Character was deleted.")
                // Здесь нужно обработать удаление, например, закрыть View
                self.notificationToken?.invalidate()
            case .error(let error):
                print("CharacterDetailVM: Error observing character: \(error)")
            }
        }
    }
    
    deinit {
        notificationToken?.invalidate()
    }

    func toggleEditMode() {
        isEditing.toggle()
        if isEditing {
            // При входе в режим редактирования, копируем данные из character в editable поля
            syncEditableFieldsFromCharacter()
        }
    }

    func syncEditableFieldsFromCharacter() {
        editableName = character.name
        editableRace = character.race
        editableClassName = character.className
        editableLevel = character.level
        editableStrength = character.strength
        editableDexterity = character.dexterity
        editableConstitution = character.constitution
        editableIntelligence = character.intelligence
        editableWisdom = character.wisdom
        editableCharisma = character.charisma
        editableCurrentHP = character.currentHP
        editableMaxHP = character.maxHP
        inventoryItems = Array(character.inventoryItems) // Обновляем копию инвентаря
        
        selectedAvatarTypeDuringEdit = character.avatarImageType
        selectedTemplateAssetNameDuringEdit = character.avatarAssetName
        customAvatarDataDuringEdit = character.avatarData
        if character.avatarImageType == .customFromGalleryOrCamera, let data = character.avatarData, let uiImage = UIImage(data: data) {
            customAvatarImageDuringEdit = Image(uiImage: uiImage)
        } else {
            customAvatarImageDuringEdit = nil
        }
    }

    func saveChanges() {
        RealmManager.shared.updateCharacter(id: character.id) { [weak self] (charObjectInWriteTransaction) in
            guard let self = self else { return } // self все еще нужно проверять, так как он [weak]

            charObjectInWriteTransaction.name = self.editableName
            charObjectInWriteTransaction.race = self.editableRace
            charObjectInWriteTransaction.className = self.editableClassName
            charObjectInWriteTransaction.level = self.editableLevel
            
            charObjectInWriteTransaction.strength = self.editableStrength
            charObjectInWriteTransaction.dexterity = self.editableDexterity
            charObjectInWriteTransaction.constitution = self.editableConstitution
            charObjectInWriteTransaction.intelligence = self.editableIntelligence
            charObjectInWriteTransaction.wisdom = self.editableWisdom
            charObjectInWriteTransaction.charisma = self.editableCharisma
            
            // Валидация HP
            charObjectInWriteTransaction.maxHP = max(1, self.editableMaxHP) // Max HP не может быть меньше 1
            charObjectInWriteTransaction.currentHP = min(self.editableCurrentHP, charObjectInWriteTransaction.maxHP) // Текущее HP не больше максимального
            charObjectInWriteTransaction.currentHP = max(0, charObjectInWriteTransaction.currentHP) // И не меньше 0
            
            // Аватар
            charObjectInWriteTransaction.avatarImageType = self.selectedAvatarTypeDuringEdit
            switch self.selectedAvatarTypeDuringEdit {
            case .template:
                charObjectInWriteTransaction.avatarAssetName = self.selectedTemplateAssetNameDuringEdit
                charObjectInWriteTransaction.avatarData = nil
            case .customFromGalleryOrCamera:
                charObjectInWriteTransaction.avatarData = self.customAvatarDataDuringEdit
                charObjectInWriteTransaction.avatarAssetName = nil
            case .placeholder:
                charObjectInWriteTransaction.avatarAssetName = nil
                charObjectInWriteTransaction.avatarData = nil
            }
            
            // Обновление инвентаря (если мы редактировали локальную копию inventoryItems)
            // Это более сложный сценарий, если нужно отслеживать добавленные/удаленные/измененные предметы.
            // Простой вариант - заменить весь список, если это допустимо.
            // НО! Realm List нельзя просто присвоить. Нужно очистить и добавить заново или мержить.
            // Для EmbeddedObject проще очистить и добавить.
            charObjectInWriteTransaction.inventoryItems.removeAll()
                        self.inventoryItems.forEach { localItem in
                            let newItemInRealm = InventoryItemObject()
                            newItemInRealm.id = localItem.id
                            newItemInRealm.itemName = localItem.itemName
                            newItemInRealm.itemDescription = localItem.itemDescription
                            newItemInRealm.quantity = localItem.quantity
                            newItemInRealm.isEquipped = localItem.isEquipped
                            charObjectInWriteTransaction.inventoryItems.append(newItemInRealm)
                        }
        }
        isEditing = false // Выходим из режима редактирования
    }
    
    func cancelEdit() {
        syncEditableFieldsFromCharacter() // Возвращаем значения из character
        isEditing = false
    }
    
    // MARK: - Inventory Management
    func addItemToInventory() {
        guard !newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newItem = InventoryItemObject()
        newItem.itemName = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        // Добавляем в локальный массив @Published. При сохранении это перенесется в Realm.
        inventoryItems.append(newItem)
        newItemName = "" // Очищаем поле ввода
    }

    func deleteInventoryItem(at offsets: IndexSet) {
        inventoryItems.remove(atOffsets: offsets)
    }
    
    func toggleItemEquipped(_ item: InventoryItemObject) {
        if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
            // Создаем новый объект с измененным состоянием, т.к. EmbeddedObject не могут быть изменены "напрямую"
            // если они часть @Published массива вне write транзакции Realm.
            // Однако, если inventoryItems это просто [InventoryItemObject], то можно менять.
            // Но при сохранении в Realm все равно нужно будет создать новые.
            
            // Простой способ: меняем свойство в локальной копии.
            // При сохранении персонажа, весь список inventoryItems будет пересоздан в Realm.
            inventoryItems[index].isEquipped.toggle()
        }
    }

    // MARK: - Avatar Editing
    func handlePickedImageDuringEdit(_ image: UIImage?) {
        guard let pickedImage = image else { return }
        if let imageData = pickedImage.jpegData(compressionQuality: 0.8) {
            self.customAvatarDataDuringEdit = imageData
            self.customAvatarImageDuringEdit = Image(uiImage: pickedImage)
            self.selectedAvatarTypeDuringEdit = .customFromGalleryOrCamera
            self.selectedTemplateAssetNameDuringEdit = nil
        }
    }
    
    func selectTemplateAvatarDuringEdit(assetName: String) {
        self.selectedTemplateAssetNameDuringEdit = assetName
        self.customAvatarImageDuringEdit = nil
        self.customAvatarDataDuringEdit = nil
        self.selectedAvatarTypeDuringEdit = .template
    }
}
