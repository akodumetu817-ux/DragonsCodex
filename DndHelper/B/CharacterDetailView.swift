//
//  CharacterDetailView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//


import SwiftUI
import RealmSwift

struct CharacterDetailView: View {
    // ViewModel будет инициализирован с characterId
    @StateObject private var viewModel: CharacterDetailViewModel
    @Environment(\.dismiss) var dismiss

    init(characterId: ObjectId) {
        _viewModel = StateObject(wrappedValue: CharacterDetailViewModel(characterId: characterId))
    }

    var body: some View {
        // Проверяем, не был ли персонаж удален (isInvalidated)
        if viewModel.character.isInvalidated {
            VStack {
                Text("Character has been deleted.")
                    .font(.custom(AppFontName.aclonicaRegular, size: 18))
                    .foregroundColor(.secondaryText)
                Button("Go Back") {
                    dismiss()
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .tint(Color.accentCol)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
        } else {
            Form {
                // Секция Аватара и основной информации
                characterHeaderSection
                
                // Секция Характеристик
                attributesSection
                
                // Секция Здоровья
                healthSection
                
                // Секция Инвентаря
                inventorySection
            }
            .font(.custom(AppFontName.aclonicaRegular, size: 14))
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(viewModel.isEditing ? "Edit Character" : viewModel.character.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditing {
                        HStack {
                            Button("Cancel") { viewModel.cancelEdit() }
                                .font(.custom(AppFontName.aclonicaRegular, size: 14))
                            Button("Save") { viewModel.saveChanges() }
                                .font(.custom(AppFontName.aclonicaRegular, size: 14)).bold()
                        }
                        .foregroundColor(Color.accentCol)
                    } else {
                        Button("Edit") { viewModel.toggleEditMode() }
                            .font(.custom(AppFontName.aclonicaRegular, size: 14))
                            .foregroundColor(Color.accentCol)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingImagePickerSheet) { // Для выбора аватара при редактировании
                 ImagePickerSheetView(
                    // Передаем замыкания для обработки выбора
                    onTemplateSelected: { assetName in
                        viewModel.selectTemplateAvatarDuringEdit(assetName: assetName)
                        viewModel.showingImagePickerSheet = false
                    },
                    onImagePickedFromDevice: { uiImage in
                        viewModel.handlePickedImageDuringEdit(uiImage)
                        viewModel.showingImagePickerSheet = false
                    },
                    // Передаем текущие значения для отображения в ImagePickerSheetView
                    currentTemplate: viewModel.selectedTemplateAssetNameDuringEdit,
                    templateAvatars: viewModel.templateAvatars
                 )
            }
        }
    }

    // MARK: - Subviews for CharacterDetailView
    
    private var characterHeaderSection: some View {
        Section {
            HStack {
                Spacer()
                VStack(alignment: .center, spacing: 10) {
                    // Avatar Display (похож на CharacterHomeCardView, но для редактируемых данных)
                    Group {
                        // В режиме редактирования показываем то, что выбрано в ViewModel
                        if viewModel.isEditing {
                            if let customEditImg = viewModel.customAvatarImageDuringEdit {
                                customEditImg.resizable().aspectRatio(contentMode: .fill)
                            } else if let templateEditName = viewModel.selectedTemplateAssetNameDuringEdit, !templateEditName.isEmpty {
                                Image(templateEditName).resizable().aspectRatio(contentMode: .fit)
                            } else { defaultDetailAvatarImage }
                        } else { // В режиме просмотра показываем из character
                            switch viewModel.character.avatarImageType {
                            case .customFromGalleryOrCamera:
                                if let data = viewModel.character.avatarData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                                } else { defaultDetailAvatarImage }
                            case .template:
                                if let name = viewModel.character.avatarAssetName, !name.isEmpty {
                                    Image(name).resizable().aspectRatio(contentMode: .fit)
                                } else { defaultDetailAvatarImage }
                            case .placeholder:
                                defaultDetailAvatarImage
                            }
                        }
                    }
                    .frame(width: 150, height: 150)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.secondaryText, lineWidth: 1))
                    
                    if viewModel.isEditing {
                        Button("Change Avatar") { viewModel.showingImagePickerSheet = true }
                            .font(.custom(AppFontName.aclonicaRegular, size: 12))
                            .tint(Color.accentCol)
                    }

                    if viewModel.isEditing {
                        TextField("Name", text: $viewModel.editableName)
                            .font(.custom(AppFontName.aclonicaRegular, size: 24))
                            .multilineTextAlignment(.center).foregroundColor(Color.primaryText)
                        HStack {
                            TextField("Race", text: $viewModel.editableRace).foregroundColor(Color.primaryText)
                            Text("/").foregroundColor(Color.secondaryText)
                            TextField("Class", text: $viewModel.editableClassName).foregroundColor(Color.primaryText)
                        }
                        .font(.custom(AppFontName.aclonicaRegular, size: 16))
                        .multilineTextAlignment(.center)
                        
                        Stepper("Level: \(viewModel.editableLevel)", value: $viewModel.editableLevel, in: 1...20)
                            .foregroundColor(Color.primaryText)
                    } else {
                        Text(viewModel.character.name)
                            .font(.custom(AppFontName.aclonicaRegular, size: 26))
                            .foregroundColor(Color.primaryText)
                        Text("\(viewModel.character.race) / \(viewModel.character.className)")
                            .font(.custom(AppFontName.aclonicaRegular, size: 18))
                            .foregroundColor(Color.secondaryText)
                        Text("Level \(viewModel.character.level)")
                            .font(.custom(AppFontName.aclonicaRegular, size: 16))
                            .foregroundColor(Color.accentCol)
                    }
                }
                Spacer()
            }
            .padding(.vertical)
        }
        .listRowBackground(Color.cardBackground.opacity(0.7))
    }
    
    private var defaultDetailAvatarImage: some View {
        Image(systemName: "person.fill")
            .resizable().scaledToFit().foregroundColor(Color.secondaryText).padding(40)
    }

    private var attributesSection: some View {
        Section(header: Text("Attributes").font(.custom(AppFontName.aclonicaRegular, size: 16))) {
            if viewModel.isEditing {
                attributeEditorStepper(title: "STR", value: $viewModel.editableStrength)
                attributeEditorStepper(title: "DEX", value: $viewModel.editableDexterity)
                attributeEditorStepper(title: "CON", value: $viewModel.editableConstitution)
                attributeEditorStepper(title: "INT", value: $viewModel.editableIntelligence)
                attributeEditorStepper(title: "WIS", value: $viewModel.editableWisdom)
                attributeEditorStepper(title: "CHA", value: $viewModel.editableCharisma)
            } else {
                attributeDisplayRow(title: "STR", value: viewModel.character.strength)
                attributeDisplayRow(title: "DEX", value: viewModel.character.dexterity)
                attributeDisplayRow(title: "CON", value: viewModel.character.constitution)
                attributeDisplayRow(title: "INT", value: viewModel.character.intelligence)
                attributeDisplayRow(title: "WIS", value: viewModel.character.wisdom)
                attributeDisplayRow(title: "CHA", value: viewModel.character.charisma)
            }
        }
        .listRowBackground(Color.cardBackground)
    }
    
    private func attributeDisplayRow(title: String, value: Int) -> some View {
        HStack {
            Text(title).foregroundColor(Color.primaryText)
            Spacer()
            Text("\(value) (\(modifier(for: value)))").foregroundColor(Color.secondaryText)
        }
    }
    
    private func attributeEditorStepper(title: String, value: Binding<Int>) -> some View {
        Stepper("\(title): \(value.wrappedValue) (\(modifier(for: value.wrappedValue)))", value: value, in: 1...30) // Статы могут быть выше 20 с магией
            .foregroundColor(Color.primaryText)
    }
    
    private func modifier(for score: Int) -> String {
        let mod = (score - 10) / 2
        return mod >= 0 ? "+\(mod)" : "\(mod)"
    }

    private var healthSection: some View {
        Section(header: Text("Health").font(.custom(AppFontName.aclonicaRegular, size: 16))) {
            if viewModel.isEditing {
                Stepper("Current HP: \(viewModel.editableCurrentHP)", value: $viewModel.editableCurrentHP, in: 0...viewModel.editableMaxHP)
                    .foregroundColor(Color.primaryText)
                Stepper("Max HP: \(viewModel.editableMaxHP)", value: $viewModel.editableMaxHP, in: 1...999)
                    .foregroundColor(Color.primaryText)
            } else {
                HStack {
                    Text("Current HP").foregroundColor(Color.primaryText)
                    Spacer()
                    Text("\(viewModel.character.currentHP) / \(viewModel.character.maxHP)").foregroundColor(Color.secondaryText)
                }
                // Прогресс-бар для HP
                ProgressView(value: Double(viewModel.character.currentHP), total: Double(max(1, viewModel.character.maxHP))) // total не может быть 0
                    .tint(hpColor(current: viewModel.character.currentHP, max: viewModel.character.maxHP))
            }
        }
        .listRowBackground(Color.cardBackground)
    }
    
    private func hpColor(current: Int, max: Int) -> Color {
          // Ошибка здесь: Swift.max() это функция, а не свойство Int.
          // let percentage = Double(current) / Double(max(1,max))
          let percentage = Double(current) / Double(Swift.max(1, max)) // Используем Swift.max для чисел
          if percentage > 0.5 { return .green }
          if percentage > 0.25 { return .yellow }
          return .red
      }

    private var inventorySection: some View {
        
        Section(header: Text("Inventory & Equipment")) {
            if viewModel.isEditing {
                HStack {
                    TextField("New item name", text: $viewModel.newItemName)
                        .foregroundColor(Color.primaryText)
                    Button(action: viewModel.addItemToInventory) {
                        Image(systemName: "plus.circle.fill").foregroundColor(Color.accentCol)
                    }
                    .disabled(viewModel.newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            if viewModel.inventoryItems.isEmpty {
                Text("Inventory is empty.")
                    .foregroundColor(.secondaryText)
                    .padding(.vertical, viewModel.isEditing ? 0 : 10) // Меньше отступ в режиме редактирования, если есть поле ввода
            } else {
                ForEach(viewModel.inventoryItems) { item in // Используем локальную копию inventoryItems
                    HStack {
                        Text(item.itemName)
                            .foregroundColor(Color.primaryText)
                        if item.quantity > 1 {
                            Text("x\(item.quantity)")
                                .font(.caption)
                                .foregroundColor(Color.secondaryText)
                        }
                        Spacer()
                        if viewModel.isEditing {
                            // В режиме редактирования можно добавить кнопки +/- для количества или удаления
                            // Сейчас просто отображаем
                            Image(systemName: item.isEquipped ? "shield.lefthalf.filled" : "circle") // Пример иконки экипировки
                                .foregroundColor(item.isEquipped ? Color.accentCol : Color.secondaryText)
                                .onTapGesture {
                                    if viewModel.isEditing { // Меняем только в режиме редактирования
                                        viewModel.toggleItemEquipped(item)
                                    }
                                }
                        } else {
                            if item.isEquipped {
                                Image(systemName: "shield.lefthalf.filled") // Или другая иконка для "экипировано"
                                    .foregroundColor(Color.accentCol)
                            }
                        }
                    }
                }
              //  .onDelete(perform: viewModel.isEditing ? viewModel.deleteInventoryItem : nil) // Удаление только в режиме редактирования
            }
        }
        .listRowBackground(Color.cardBackground)
    }
}

// Обновляем ImagePickerSheetView, чтобы он мог работать с замыканиями
// Это нужно, если мы не хотим передавать весь CharacterDetailViewModel в него
struct ImagePickerSheetView: View {
    var onTemplateSelected: (String) -> Void
    var onImagePickedFromDevice: (UIImage?) -> Void
    var currentTemplate: String?
    let templateAvatars: [String: String]

    @Environment(\.dismiss) var dismissSheet
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(templateAvatars.sorted(by: { $0.key < $1.key }), id: \.key) { assetName, displayName in
                            Button {
                                onTemplateSelected(assetName)
                                // dismissSheet() // Закрытие управляется из родительского View
                            } label: {
                                VStack {
                                    Image(assetName)
                                        .resizable().aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .background(Color.black.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius:10))
                                        .overlay(RoundedRectangle(cornerRadius:10)
                                            .stroke(currentTemplate == assetName ? Color.accentCol : Color.clear, lineWidth: 2)
                                        )
                                    Text(displayName).font(.custom(AppFontName.aclonicaRegular, size: 10)).foregroundColor(Color.primaryText)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(height: 130)
                .background(Color.cardBackground.opacity(0.5))
                Divider()
                List {
                    Button { showingPhotoPicker = true } label: {
                        HStack { Image(systemName: "photo.on.rectangle.angled"); Text("Choose from Gallery") }
                    }
                    .foregroundColor(Color.accentCol)
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button { showingCamera = true } label: {
                            HStack { Image(systemName: "camera.fill"); Text("Take Photo") }
                        }
                        .foregroundColor(Color.accentCol)
                    }
                }
                .font(.custom(AppFontName.aclonicaRegular, size: 14)).listStyle(.plain)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Select Avatar").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismissSheet() }.font(.custom(AppFontName.aclonicaRegular, size: 14)).foregroundColor(Color.accentCol)
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(onImagePicked: { image in
                    onImagePickedFromDevice(image)
                    // dismissSheet() // Закрытие управляется из родительского View
                })
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker(onImagePicked: { image in
                    onImagePickedFromDevice(image)
                    // dismissSheet()
                }).ignoresSafeArea()
            }
        }
        .accentColor(Color.accentCol)
    }
}

