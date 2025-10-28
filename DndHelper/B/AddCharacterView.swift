//
//  AddCharacterView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import Foundation
// File: AddCharacterView.swift
import SwiftUI
import PhotosUI // Для нового PHPickerViewController

struct AddCharacterView: View {
    @StateObject private var viewModel = AddCharacterViewModel()
    @Environment(\.dismiss) var dismiss // Для закрытия View
    
    var body: some View {
        NavigationView { // Или NavigationStack
            Form {
                Section(header: Text("Basic Information").font(.custom(AppFontName.aclonicaRegular, size: 16))) {
                    characterAvatarSection
                    formTextField(title: "Name", text: $viewModel.name)
                    formTextField(title: "Race", text: $viewModel.race)
                    formTextField(title: "Class", text: $viewModel.className) // Имя поля в UI может быть "Class"
                    
                    Stepper("Level: \(viewModel.level)", value: $viewModel.level, in: 1...20)
                        .font(.custom(AppFontName.aclonicaRegular, size: 14))
                        .foregroundColor(Color.primaryText)
                }
                .listRowBackground(Color.cardBackground)
                
                
                Section(header: Text("Attributes").font(.custom(AppFontName.aclonicaRegular, size: 16))) {
                    attributeStepper(title: "Strength", value: $viewModel.strength)
                    attributeStepper(title: "Dexterity", value: $viewModel.dexterity)
                    attributeStepper(title: "Constitution", value: $viewModel.constitution)
                    attributeStepper(title: "Intelligence", value: $viewModel.intelligence)
                    attributeStepper(title: "Wisdom", value: $viewModel.wisdom)
                    attributeStepper(title: "Charisma", value: $viewModel.charisma)
                }
                .listRowBackground(Color.cardBackground)
                
                Section(header: Text("Hit Points").font(.custom(AppFontName.aclonicaRegular, size: 16))) {
                    Stepper("Max HP: \(viewModel.maxHP)", value: $viewModel.maxHP, in: 1...300, step: 1) // Шаг можно настроить
                        .font(.custom(AppFontName.aclonicaRegular, size: 14))
                        .foregroundColor(Color.primaryText)
                }
                .listRowBackground(Color.cardBackground)
                
                if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .font(.custom(AppFontName.aclonicaRegular, size: 12))
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.cardBackground)
                }
                
                Section {
                    Button(action: {
                        if viewModel.saveCharacter() {
                            dismiss() // Закрываем View, если сохранение успешно
                        }
                    }) {
                        Text("Save Character")
                            .font(.custom(AppFontName.aclonicaRegular, size: 18))
                            .foregroundColor(viewModel.canSave ? Color.buttonTextOnYellow : Color.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(viewModel.canSave ? Color.accentCol : Color.gray.opacity(0.5))
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.canSave)
                }
                .listRowBackground(Color.clear) // Убираем фон для секции с кнопкой
                
            }
            .font(.custom(AppFontName.aclonicaRegular, size: 14)) // Шрифт по умолчанию для Form
            .scrollContentBackground(.hidden) // Делает фон Form прозрачным для iOS 16+
            .background(Color.appBackground.ignoresSafeArea()) // Фон всего View
            .navigationTitle("New Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar) // Для светлого текста в NavBar
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom(AppFontName.aclonicaRegular, size: 14))
                    .foregroundColor(Color.accentCol)
                }
            }
            // Модификатор .sheet для выбора изображения
            // В AddCharacterView.swift
            
            // ... (начало AddCharacterView) ...
            .sheet(isPresented: $viewModel.showingImagePickerSheet) {
                // Используем ImagePickerSheetView с замыканиями,
                // которые вызывают методы нашего AddCharacterViewModel
                ImagePickerSheetView(
                    onTemplateSelected: { assetName in
                        viewModel.selectTemplateAvatar(assetName: assetName) // Метод из AddCharacterViewModel
                        viewModel.showingImagePickerSheet = false // Закрываем sheet
                    },
                    onImagePickedFromDevice: { uiImage in
                        viewModel.handlePickedImage(uiImage) // Метод из AddCharacterViewModel
                        viewModel.showingImagePickerSheet = false // Закрываем sheet
                    },
                    currentTemplate: viewModel.selectedTemplateAssetName, // Из AddCharacterViewModel
                    templateAvatars: viewModel.templateAvatars // Из AddCharacterViewModel
                )
            }
            // ... (конец AddCharacterView) ...
        }
        .accentColor(Color.accentCol) // Цвет для системных элементов, например, курсора в TextField
    }
    
    // MARK: - Subviews for Form
    private var characterAvatarSection: some View {
        HStack {
            Spacer()
            VStack {
                Group {
                    if let customImage = viewModel.customAvatarImage {
                        customImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if let templateName = viewModel.selectedTemplateAssetName,
                              let uiImage = UIImage(named: templateName) { // Предполагаем, что шаблоны в Assets.xcassets
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus") // Плейсхолдер
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(Color.secondaryText)
                            .padding(20) // Отступы для SF Symbol
                    }
                }
                .frame(width: 120, height: 120)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 15)) // Или Circle()
                .overlay(
                    RoundedRectangle(cornerRadius: 15) // Или Circle()
                        .stroke(Color.secondaryText, lineWidth: 1)
                )
                
                Button {
                    viewModel.showingImagePickerSheet = true
                } label: {
                    Text("Choose Avatar")
                        .font(.custom(AppFontName.aclonicaRegular, size: 12))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.accentCol.opacity(0.8))
                        .foregroundColor(Color.buttonTextOnYellow)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            Spacer()
        }
        .padding(.vertical)
    }
    
    private func formTextField(title: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(title).foregroundColor(.gray))
            .font(.custom(AppFontName.aclonicaRegular, size: 14))
            .foregroundColor(Color.primaryText)
        // .keyboardType(...) // Можно настроить тип клавиатуры
    }
    
    private func attributeStepper(title: String, value: Binding<Int>) -> some View {
        Stepper("\(title): \(value.wrappedValue)", value: value, in: 3...20) // Обычный диапазон для статов D&D
            .font(.custom(AppFontName.aclonicaRegular, size: 14))
            .foregroundColor(Color.primaryText)
    }
}



// MARK: - UIKit Image Pickers (обертки для SwiftUI)

// 1. PhotoPicker (использует PhotosUI - PHPickerViewController, рекомендуется для iOS 14+)
struct PhotoPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images // Только изображения
        config.selectionLimit = 1 // Только одно изображение
        // config.preferredAssetRepresentationMode = .current // Для получения оригинального качества
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                parent.onImagePicked(nil)
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    // Выполняем на главном потоке, так как это обновление UI (хоть и через замыкание)
                    DispatchQueue.main.async {
                        self.parent.onImagePicked(image as? UIImage)
                    }
                }
            } else {
                parent.onImagePicked(nil)
            }
        }
    }
}

// 2. CameraPicker (использует UIImagePickerController)
struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage?) -> Void
    @Environment(\.dismiss) var dismiss // Для закрытия, если нужно
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false // Или true, если нужна базовая обрезка
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var pickedImage: UIImage?
            if let editedImage = info[.editedImage] as? UIImage {
                pickedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                pickedImage = originalImage
            }
            parent.onImagePicked(pickedImage)
            // parent.dismiss() // Закрываем CameraPicker, если он не закрывается автоматически
            // Обычно dismiss() вызывается на самом пикере.
            // Если он в fullScreenCover, то isPresented сам его закроет.
            picker.dismiss(animated: true) // Явно закрываем сам UIImagePickerController
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            // parent.dismiss()
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview
struct AddCharacterView_Previews: PreviewProvider {
    static var previews: some View {
        AddCharacterView()
            .preferredColorScheme(.dark) // Для соответствия стилю приложения
    }
}
