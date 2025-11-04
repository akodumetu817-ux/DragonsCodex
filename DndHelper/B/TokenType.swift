//
//  SwiftUIView.swift
//  Melbe
//
//  Created by D K on 08.05.2025.
//

import SwiftUI // Убедись, что импорт есть


// Тип токена
enum TokenType: String, CaseIterable, Identifiable, Hashable { // Добавил Hashable для Picker
    case hero = "Hero"
    case villain = "Villain"
    case npc = "NPC"
    case generic = "Generic"
    
    var id: String { self.rawValue }
    
    // Соответствующий SF Symbol
    var iconName: String {
        switch self {
        case .hero: return "figure.stand" // Изменил иконку героя
        case .villain: return "figure.badminton" // Оставил эту пока что
        case .npc: return "figure.walk"
        case .generic: return "questionmark.diamond.fill" // Изменил иконку
        }
    }
}
// Модель токена
struct Token: Identifiable, Equatable {
    let id = UUID()
    var name: String
    // 'position' будет хранить координаты ОТНОСИТЕЛЬНО mapSize (размера отображенного Image)
    var position: CGPoint
    var color: Color
    var hp: String
    var ac: String
    var tokenType: TokenType = .generic // <--- ДОБАВЛЕНО
    // iconName больше не нужен напрямую
}

// В AddTokenView
@available(iOS 16.0, *)
struct AddTokenView: View {
    @Environment(\.dismiss) var dismiss
    // Меняем замыкание: добавляем TokenType
    var onAddToken: (String, Color, TokenType) -> Void // <--- ИЗМЕНЕНО

    @State private var tokenName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedType: TokenType = .generic // <--- ДОБАВЛЕНО

    let predefinedColors: [Color] = [.red, .green, .blue, .orange, .purple, .yellow, .pink, .cyan, .indigo, .mint]
    let allTokenTypes = TokenType.allCases // Для пикера

    // Цвета UI (возьми из своей палитры)
    let backgroundColor = Color.appBackground
    let cardColor = Color.cardBackground
    let accentColor = Color.accentCol

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Token Details").modifier(FormHeaderModifier())) { // Используем модификатор
                    TextField("Token Name", text: $tokenName)
                        .modifier(FormFieldTextModifier()) // Используем модификатор

                    // Выбор типа токена
                    Picker("Token Type", selection: $selectedType) {
                        ForEach(allTokenTypes) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                    .modifier(FormFieldTextModifier()) // Шрифт и цвет
                    .pickerStyle(.menu)

                    ColorPicker("Token Color", selection: $selectedColor, supportsOpacity: false)
                       .modifier(FormFieldTextModifier()) // Шрифт и цвет
                }
                .listRowBackground(cardColor) // Фон строки


                Button("Add Token") {
                    if !tokenName.isEmpty {
                        onAddToken(tokenName, selectedColor, selectedType) // <--- ПЕРЕДАЕМ ТИП
                        dismiss()
                    }
                }
                .disabled(tokenName.isEmpty)
                .modifier(PrimaryButtonModifier()) // Используем модификатор для кнопки
                .listRowBackground(Color.clear)

            }
            .scrollContentBackground(.hidden)
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Add New Token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                       .font(.custom(AppFontName.aclonicaRegular, size: 14))
                       .foregroundColor(accentColor)
                }
            }
        }
        .accentColor(accentColor)
    }
}

// Модификаторы для Form (чтобы не повторять код)
struct FormHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom(AppFontName.aclonicaRegular, size: 14))
            .foregroundColor(Color.secondaryText) // Из палитры
            .padding(.leading, -5) // Небольшой отступ для заголовка секции
    }
}

struct FormFieldTextModifier: ViewModifier {
     func body(content: Content) -> some View {
         content
            .font(.custom(AppFontName.aclonicaRegular, size: 14))
            .foregroundColor(Color.primaryText) // Из палитры
     }
 }

// В основном файле CampaignMapView.swift
import SwiftUI
import PhotosUI

// MARK: - Main Campaign Map View
@available(iOS 16.0, *)
struct CampaignMapView: View {
    // MARK: - State Variables
    @State private var selectedMapImage: Image?
    @State private var selectedMapUIImage: UIImage? // Для получения размера
    @State private var mapContentRenderedSize: CGSize = .zero

    @State private var tokens: [Token] = []

    @State private var showingAddTokenSheet = false
    @State private var showingImagePicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showGrid: Bool = false // Состояние для сетки

    @State private var zoomScale: CGFloat = 1.0
    @State private var currentDragOffset: CGSize = .zero
    @State private var finalDragOffset: CGSize = .zero

    let backgroundColor = Color.appBackground
    let cardColor = Color.cardBackground
    let accentColor = Color.accentCol

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)

                ScrollView {
                    NewHeaderView(title: "Campaign Map", description: "Upload your own maps and manage markers.")
                    
                    VStack(spacing: 15) {
                        
                        uploadMapButton

                        mapAreaView
                            .aspectRatio(originalMapSize == .zero ? 1.0 : originalMapSize.width / originalMapSize.height, contentMode: .fit)
                            .background(cardColor) // Фон области карты
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .shadow(radius: 3)

                        mapControlsView
                            .padding(.horizontal)

                        Text("Active Tokens")
                            .modifier(SectionTitleModifier())
                            .padding(.horizontal)

                        activeTokensListView
                             .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.bottom)
                }
                .scrollIndicators(.hidden)
            }
            .sheet(isPresented: $showingAddTokenSheet) {
                 AddTokenView { name, color, type in
                    let centerPosition = CGPoint(x: mapContentRenderedSize.width / 2, y: mapContentRenderedSize.height / 2)
                    let newToken = Token(
                        name: name,
                        position: centerPosition,
                        color: color,
                        hp: "10/10",
                        ac: "AC: 10",
                        tokenType: type
                    )
                    tokens.append(newToken)
                 }
                 .presentationDetents([.height(400), .large])
                 .presentationDragIndicator(.visible)
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $photoPickerItem, matching: .images)
            .onChange(of: photoPickerItem) { newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data) else {
                        print("Failed to load image data")
                        return
                    }
                    selectedMapUIImage = uiImage
                    selectedMapImage = Image(uiImage: uiImage)
                    zoomScale = 1.0
                    currentDragOffset = .zero
                    finalDragOffset = .zero
                    tokens.removeAll()
                    showGrid = false
                    mapContentRenderedSize = .zero
                    print("Map loaded. Original Size: \(uiImage.size)")
                }
            }
        }
        .accentColor(accentColor)
    }

    // MARK: - Computed Properties
    var originalMapSize: CGSize {
        selectedMapUIImage?.size ?? .zero
    }

    // MARK: - Subviews

    private var uploadMapButton: some View {
        Button(action: { showingImagePicker = true }) {
            HStack { Image(systemName: "square.and.arrow.up"); Text("Upload Map") }
                .modifier(PrimaryButtonModifier()) // Применяем модификатор
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var mapAreaView: some View {
        GeometryReader { geometryProxy in
             ZStack {
                ZStack(alignment: .topLeading) {
                     if let mapImg = selectedMapImage {
                        mapImg
                            .resizable()
                            .scaledToFit()
                            .background(GeometryReader { geo in
                                Color.clear.onAppear { updateMapContentRenderedSize(geo.size) }
                                          .onChange(of: geo.size) { updateMapContentRenderedSize($0) }
                            })
                            .overlay(
                                Group {
                                    if showGrid && mapContentRenderedSize.width > 0 {
                                        let originalGridSize: CGFloat = 50
                                        let scaledGridSize = originalGridSize * zoomScale
                                        SimpleGridView(gridSize: scaledGridSize)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1.0) // Фикс толщина
                                            .frame(width: mapContentRenderedSize.width, height: mapContentRenderedSize.height)
                                            .clipped()
                                    }
                                }
                            )
                            .overlay(tokenOverlayView)

                     } else {
                       //  NoMapViewPlaceholder() // Как раньше
                     }
                 }
                 .scaleEffect(zoomScale)
                 .offset(x: finalDragOffset.width + currentDragOffset.width, y: finalDragOffset.height + currentDragOffset.height)
                 .gesture(
                     DragGesture(minimumDistance: 1)
                         .onChanged { value in currentDragOffset = value.translation }
                         .onEnded { value in
                             finalDragOffset.width += value.translation.width
                             finalDragOffset.height += value.translation.height
                             currentDragOffset = .zero
                         }
                 )
                 .simultaneousGesture(
                     MagnificationGesture()
                         .onEnded { value in
                             zoomScale = max(0.2, min(zoomScale * value, 5.0))
                         }
                 )
                 
                 .frame(width: geometryProxy.size.width, height: geometryProxy.size.height)


                 VStack {
                     Spacer()
                     HStack {
                         Spacer()
                         ZoomControlsView(zoomScale: $zoomScale)
                             .padding(10)
                             .background(Material.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                             .padding(10)
                     }
                 }
             }
             .frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
             .clipped()
        }
    }

    private func updateMapContentRenderedSize(_ newSize: CGSize) {
        guard newSize != .zero, mapContentRenderedSize != newSize else { return }
        print("Updating mapContentRenderedSize to: \(newSize)")
        mapContentRenderedSize = newSize
       
    }

    @ViewBuilder
    private var tokenOverlayView: some View {
        if mapContentRenderedSize != .zero {
            ZStack {
                ForEach($tokens) { $tokenData in
                    DraggableTokenView(token: $tokenData, mapBounds: mapContentRenderedSize)
                }
            }
            .frame(width: mapContentRenderedSize.width, height: mapContentRenderedSize.height)
        } else {
            EmptyView()
        }
    }

    private var mapControlsView: some View {
        HStack(spacing: 10) {
            ControlButton(icon: "grid", text: "Toggle\nGrid", action: { showGrid.toggle() }, isActive: showGrid)
            ControlButton(icon: "plus.circle.fill", text: "Add\nToken", action: { showingAddTokenSheet = true })
            ControlButton(icon: "trash.fill", text: "Clear\nMap", action: {
                selectedMapImage = nil
                selectedMapUIImage = nil
                tokens.removeAll()
                mapContentRenderedSize = .zero
                zoomScale = 1.0
                finalDragOffset = .zero
                showGrid = false
            })
        }
    }

    private var activeTokensListView: some View {
         List {
             ForEach(tokens) { token in
                 ActiveTokenRow(token: token)
                     .listRowBackground(cardColor)
                     .listRowSeparator(.hidden)
             }
         }
         .listStyle(.plain)
         .frame(height: tokens.isEmpty ? 60 : min(CGFloat(tokens.count * 75), 220))
         .background(backgroundColor)
         .cornerRadius(10)
         .overlay(
             Group {
                 if tokens.isEmpty {
                     Text("No tokens added yet.")
                         .font(.custom(AppFontName.aclonicaRegular, size: 14))
                         .foregroundColor(.secondaryText)
                 }
             }
         )
    }
}

// MARK: - Control Button Helper (ОБНОВЛЕННЫЙ)
struct ControlButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    var isActive: Bool = false
    let cardColor = Color.cardBackground
    let activeColor = Color.accentCol

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title3)
                Text(text)
                    .font(.custom(AppFontName.aclonicaRegular, size: 10))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isActive ? activeColor : Color.primaryText)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 55)
            .background(cardColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? activeColor : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Draggable Token View (ОБНОВЛЕННЫЙ)
struct DraggableTokenView: View {
    @Binding var token: Token
    let mapBounds: CGSize

    @GestureState private var currentDragTranslation: CGSize = .zero
    @State private var startDragPosition: CGPoint? = nil

    var body: some View {
        ZStack {
            Circle()
                .fill(token.color)
                .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1))

            Image(systemName: token.tokenType.iconName)
                .resizable().scaledToFit()
                .foregroundColor(.white.opacity(0.9))
                .padding(6)
        }
        .frame(width: 35, height: 35)
        .shadow(color: .black.opacity(0.4), radius: startDragPosition != nil ? 6 : 3, x: 0, y: startDragPosition != nil ? 4 : 2)
        .scaleEffect(startDragPosition != nil ? 1.15 : 1.0)
        .position(token.position)
        .offset(currentDragTranslation)
        .gesture(
            DragGesture(minimumDistance: 1)
                .updating($currentDragTranslation) { value, state, _ in
                    state = value.translation
                }
                .onChanged { value in
                    if startDragPosition == nil {
                        startDragPosition = token.position
                    }
                }
                .onEnded { value in
                    guard let startPos = startDragPosition else { return }
                    var finalPos = startPos
                    finalPos.x += value.translation.width
                    finalPos.y += value.translation.height

                    let radius: CGFloat = 17.5
                    finalPos.x = max(radius, min(finalPos.x, mapBounds.width - radius))
                    finalPos.y = max(radius, min(finalPos.y, mapBounds.height - radius))

                    token.position = finalPos
                    startDragPosition = nil
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: startDragPosition != nil)
    }
}

// MARK: - Active Token Row (ОБНОВЛЕННЫЙ)
struct ActiveTokenRow: View {
    let token: Token
    let diceIconColor = Color.accentCol

    var body: some View {
        HStack {
            Image(systemName: token.tokenType.iconName)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(token.color.opacity(0.8))
                .clipShape(Circle())
                .foregroundColor(.white)

            VStack(alignment: .leading) {
                Text(token.name)
                    .font(.custom(AppFontName.aclonicaRegular, size: 16))
                    .foregroundColor(Color.primaryText)
                HStack(spacing: 10) {
                    Text("HP: \(token.hp)")
                        .font(.custom(AppFontName.aclonicaRegular, size: 11))
                        .foregroundColor(Color.levelRed)
                    Text(token.ac)
                         .font(.custom(AppFontName.aclonicaRegular, size: 11))
                        .foregroundColor(Color.secondaryText)
                }
            }
            Spacer()
            
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Zoom Controls View (ОБНОВЛЕННЫЙ)
struct ZoomControlsView: View {
    @Binding var zoomScale: CGFloat
    let accentColor = Color.accentCol

    var body: some View {
        HStack(spacing: 5) {
            Button {
                withAnimation(.easeInOut) { zoomScale = max(0.2, zoomScale / 1.25) }
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }

             Text("\(Int(zoomScale * 100))%")
                .font(.custom(AppFontName.aclonicaRegular, size: 12))
                .frame(minWidth: 45)
                .padding(.horizontal, 5)


            Button {
                withAnimation(.easeInOut) { zoomScale = min(5.0, zoomScale * 1.25) }
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
        }
        .font(.title3)
        .foregroundColor(Color.primaryText)
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
    }
}

// MARK: - Simple Grid Shape (ОБНОВЛЕННЫЙ)
struct SimpleGridView: Shape {
    var gridSize: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard gridSize > 1 else { return path }

        var x = gridSize
        while x < rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += gridSize
        }

        var y = gridSize
        while y < rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += gridSize
        }
        return path
    }
}



struct SectionTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom(AppFontName.aclonicaRegular, size: 18))
            .foregroundColor(Color.primaryText)
            .padding(.bottom, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButtonModifier: ViewModifier {
     func body(content: Content) -> some View {
         content
             .font(.custom(AppFontName.aclonicaRegular, size: 16))
             .foregroundColor(Color.buttonTextOnYellow)
             .padding()
             .frame(maxWidth: .infinity)
             .background(Color.accentCol)
             .cornerRadius(10)
     }
 }


struct ErrorTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.custom(AppFontName.aclonicaRegular, size: 12))
            .foregroundColor(Color.levelRed)
    }
}
