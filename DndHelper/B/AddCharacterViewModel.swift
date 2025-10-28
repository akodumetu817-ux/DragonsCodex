//
//  AddCharacterViewModel.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//


import SwiftUI
import Combine // Для @Published, если не используется @StateObject в View напрямую для всех полей
import RealmSwift // Для ObjectId и других типов Realm, если они нужны во ViewModel

@MainActor // Все обновления UI и работа с @Published должны быть на главном потоке
class AddCharacterViewModel: ObservableObject {
    // MARK: - Form Fields
    @Published var name: String = ""
    @Published var race: String = ""
    @Published var className: String = "" // "class" - зарезервированное слово
    @Published var level: Int = 1
    
    // Avatar
    @Published var selectedAvatarType: AvatarImageType = .placeholder
    @Published var selectedTemplateAssetName: String? = nil
    @Published var customAvatarImage: Image? = nil // Для отображения выбранного кастомного Image
    private var customAvatarData: Data? = nil     // Для сохранения Data кастомного Image
    
    // Stats (можно сделать значения по умолчанию или позволить пользователю вводить)
    @Published var strength: Int = 10
    @Published var dexterity: Int = 10
    @Published var constitution: Int = 10
    @Published var intelligence: Int = 10
    @Published var wisdom: Int = 10
    @Published var charisma: Int = 10
    
    // HP
    @Published var maxHP: Int = 10
    // currentHP будет равен maxHP при создании

    // MARK: - UI State
    @Published var showingImagePickerSheet: Bool = false
    @Published var showingPhotoPicker: Bool = false // Для PhotosUI
    @Published var showingCamera: Bool = false
    
    @Published var errorMessage: String? = nil
    @Published var canSave: Bool = false // Для активации кнопки сохранения
    
    // Список шаблонных аватаров (имя ассета -> отображаемое имя или просто имя ассета)
    // Заполни реальными именами ассетов, когда они у тебя будут
    let templateAvatars: [String: String] = [
        "template_fighter": "Fighter",
        "template_wizard": "Wizard",
        "template_rogue": "Rogue",
        "template_cleric": "Cleric",
        // ... добавь остальные классы/шаблоны
        "barbarian_m": "Barbarian", // Пример
        "bard_f": "Bard",           // Пример
    ]
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Валидация для кнопки сохранения
        Publishers.CombineLatest3($name, $race, $className)
            .map { name, race, className in
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       !race.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       !className.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .assign(to: \.canSave, on: self)
            .store(in: &cancellables)
    }

    func saveCharacter() -> Bool {
        guard canSave else {
            errorMessage = "Please fill in all required fields (Name, Race, Class)."
            return false
        }
        
        let newCharacter = CharacterObject()
        newCharacter.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        newCharacter.race = race.trimmingCharacters(in: .whitespacesAndNewlines)
        newCharacter.className = className.trimmingCharacters(in: .whitespacesAndNewlines)
        newCharacter.level = level
        
        newCharacter.strength = strength
        newCharacter.dexterity = dexterity
        newCharacter.constitution = constitution
        newCharacter.intelligence = intelligence
        newCharacter.wisdom = wisdom
        newCharacter.charisma = charisma
        
        newCharacter.maxHP = maxHP
        newCharacter.currentHP = maxHP // При создании текущее HP равно максимальному
        
        // Обработка аватара
        newCharacter.avatarImageType = selectedAvatarType
        switch selectedAvatarType {
        case .template:
            newCharacter.avatarAssetName = selectedTemplateAssetName
            newCharacter.avatarData = nil
        case .customFromGalleryOrCamera:
            newCharacter.avatarData = customAvatarData
            newCharacter.avatarAssetName = nil
        case .placeholder:
            newCharacter.avatarAssetName = nil
            newCharacter.avatarData = nil
        }
        
        RealmManager.shared.addCharacter(newCharacter)
        print("Character \(newCharacter.name) prepared for saving.")
        // errorMessage = nil // Сбросить ошибку, если была
        return true
    }
    
    // Вызывается после выбора изображения из галереи/камеры
    func handlePickedImage(_ image: UIImage?) {
        guard let pickedImage = image else {
            // customAvatarImage = nil // Можно сбросить, если нужно
            // customAvatarData = nil
            return
        }
        // Сжимаем изображение для хранения (например, в JPEG)
        if let imageData = pickedImage.jpegData(compressionQuality: 0.8) {
            self.customAvatarData = imageData
            self.customAvatarImage = Image(uiImage: pickedImage) // Обновляем Image для отображения
            self.selectedAvatarType = .customFromGalleryOrCamera
            self.selectedTemplateAssetName = nil // Сбрасываем шаблон
        } else {
            print("Error converting picked image to Data.")
            errorMessage = "Could not process selected image."
        }
    }
    
    func selectTemplateAvatar(assetName: String) {
        self.selectedTemplateAssetName = assetName
        self.customAvatarImage = nil // Сбрасываем кастомное изображение
        self.customAvatarData = nil
        self.selectedAvatarType = .template
    }
}
