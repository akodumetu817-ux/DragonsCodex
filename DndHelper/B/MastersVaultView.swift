//
//  MastersVaultView.swift
//  Melbe
//
//  Created by D K on 09.05.2025.
//

import SwiftUI

// Main View
struct MastersVaultView: View {
    private let geminiService = GeminiService()
    private let screenBackgroundColor = Color.appBackground
    private let defaultFontName = "Aclonica-Regular"
    

    var body: some View {
        ZStack {
            screenBackgroundColor
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                NewHeaderView(title: "Master's Vault", description: "Create unique elements for your adventure with our powerful generators.")
                
                ScrollView {
                    VStack(spacing: 20) {
                        GeneratorView(
                            viewModel: GeneratorViewModel(
                                contentType: .quest,
                                title: "Quest Generator",
                                iconSFSymbol: "doc.text.fill",
                                initialContent: [
                                    "Plot": "A series of mysterious disappearances has plagued the village of Misthollow.",
                                    "Goal": "Investigate the abandoned mine where strange lights have been seen at night.",
                                    "Twist": "The village elder who requested help is actually controlling the creatures responsible."
                                ],
                                geminiService: geminiService,
                                fontName: defaultFontName
                            )
                        )
                        GeneratorView(
                            viewModel: GeneratorViewModel(
                                contentType: .location,
                                title: "Location Generator",
                                iconSFSymbol: "triangle.fill",
                                initialContent: [
                                    "Type": "Ancient temple ruins partially submerged in a swamp",
                                    "Atmosphere": "Eerie silence broken only by occasional echoing drips of water and distant animal calls",
                                    "Details": "Moss-covered stone statues of forgotten deities line the entrance. Strange glowing fungi illuminate parts of the interior."
                                ],
                                geminiService: geminiService,
                                fontName: defaultFontName
                            )
                        )
                        GeneratorView(
                            viewModel: GeneratorViewModel(
                                contentType: .npc,
                                title: "NPC Generator",
                                iconSFSymbol: "person.fill",
                                initialContent: [
                                    "Name": "Morvath Nightshade",
                                    "Appearance": "Tall, gaunt human with silver-streaked black hair, piercing green eyes, and a pronounced limp.",
                                    "Behavior": "Speaks softly but intensely, never making direct eye contact. Constantly fidgets with a small silver amulet.",
                                    "Motivation": "Seeks ancient knowledge to reverse a family curse, willing to help adventurers if their goals align with his research."
                                ],
                                geminiService: geminiService,
                                fontName: defaultFontName
                            )
                        )
                    }
                    .padding()
                    .padding(.bottom, 250)
                }
            }
        }
        .foregroundColor(.white)
    }
}

// Header View
struct NewHeaderView: View {
    
    let title: String
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(Font.custom("Aclonica-Regular", size: 28))
                Text(description)
                    .font(Font.custom("Aclonica-Regular", size: 14))
                    .foregroundColor(Color(white: 0.8))
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

@MainActor
class GeneratorViewModel: ObservableObject {
    let contentType: GeminiService.ContentType
    let title: String
    let iconSFSymbol: String
    let geminiService: GeminiService
    let fontName: String

    @Published var userInput: String = ""
    @Published var isInputVisible: Bool = false
    @Published var generatedData: [String: String]?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    var displayData: [String: String]? {
        return generatedData
    }

    var orderedKeys: [String] {
        switch contentType {
        case .quest:
            return ["Plot", "Goal", "Twist"]
        case .location:
            return ["Type", "Atmosphere", "Details"]
        case .npc:
            return ["Name", "Appearance", "Behavior", "Motivation"]
        }
    }

    init(contentType: GeminiService.ContentType, title: String, iconSFSymbol: String, initialContent: [String: String]? = nil, geminiService: GeminiService, fontName: String) {
        self.contentType = contentType
        self.title = title
        self.iconSFSymbol = iconSFSymbol
        self.geminiService = geminiService
        self.fontName = fontName
        if let initial = initialContent, !initial.isEmpty {
            self.generatedData = initial
        }
    }

    func toggleInputVisibility() {
        isInputVisible.toggle()
        if isInputVisible {
            userInput = ""
        }
    }

    func generateContent() {
        guard !userInput.isEmpty else {
            errorMessage = "Please enter a prompt."
            return
        }
        isLoading = true
        errorMessage = nil

        Task {
            let result = await geminiService.generateDnDContent(type: contentType, prompt: userInput)
            isLoading = false
            switch result {
            case .success(let content):
                let parsed = parseGeneratedContent(content)
                if let parsed = parsed, !parsed.isEmpty {
                    self.generatedData = parsed
                    self.isInputVisible = false
                    self.userInput = ""
                } else {
                    self.errorMessage = "Failed to parse content or content was empty. Raw: \(content)"
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func parseGeneratedContent(_ content: String) -> [String: String]? {
        var data = [String: String]()
        let lines = content.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        for line in lines {
            for key in orderedKeys {
                if line.hasPrefix("\(key):") {
                    let valueStartIndex = line.index(line.startIndex, offsetBy: key.count + 1)
                    let value = String(line[valueStartIndex...]).trimmingCharacters(in: .whitespaces)
                    data[key] = value
                    break
                }
            }
        }
        return data.isEmpty ? nil : data
    }
}

struct GeneratorView: View {
    @ObservedObject var viewModel: GeneratorViewModel

    private let cardBackgroundColor = Color(hex: "495057")
    private let buttonColor = Color(hex: "0075a5")
    private let buttonTextColor = Color.black
    private let labelColor = Color(hex: "0075a5")
    private let textFieldBackgroundColor = Color(hex: "343a40")
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: viewModel.iconSFSymbol)
                    .foregroundColor(labelColor)
                    .font(.title3)
                Text(viewModel.title)
                    .font(Font.custom(viewModel.fontName, size: 20))
                    .fontWeight(.bold)
            }

            Button(action: {
                viewModel.toggleInputVisibility()
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .renderingMode(.template)
                    Text("Generate \(viewModel.contentType.rawValue)")
                }
                .font(Font.custom(viewModel.fontName, size: 16))
                .foregroundColor(buttonTextColor)
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity)
                .background(buttonColor)
                .cornerRadius(8)
            }

            if viewModel.isInputVisible {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter your prompt below:")
                        .font(Font.custom(viewModel.fontName, size: 14))
                        .foregroundColor(Color(white: 0.9))

                    TextEditor(text: $viewModel.userInput)
                        .font(Font.custom(viewModel.fontName, size: 14))
                        .frame(height: 100)
                        .scrollContentBackground(.hidden)
                        .background(textFieldBackgroundColor)
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                       
                    


                    Button(action: {
                        viewModel.generateContent()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: buttonTextColor))
                                    .padding(.trailing, 5)
                                Text("Generating...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Get \(viewModel.contentType.rawValue)")
                            }
                        }
                        .font(Font.custom(viewModel.fontName, size: 16))
                        .foregroundColor(buttonTextColor)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .frame(maxWidth: .infinity)
                        .background(buttonColor)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading || viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } else if let data = viewModel.displayData, !data.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.orderedKeys, id: \.self) { key in
                        if let value = data[key], !value.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(key)
                                    .font(Font.custom(viewModel.fontName, size: 14))
                                    .foregroundColor(labelColor)
                                    .fontWeight(.bold)
                                Text(value)
                                    .font(Font.custom(viewModel.fontName, size: 14))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            } else if viewModel.isLoading {
                 ProgressView("Loading content...")
                    .font(Font.custom(viewModel.fontName, size: 14))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }


            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(Font.custom(viewModel.fontName, size: 12))
                    .foregroundColor(.red)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(10)
    }
}

struct MastersVaultView_Previews: PreviewProvider {
    static var previews: some View {
        MastersVaultView()
    }
}


extension UIApplication {
    func addTapGestureRecognizer() {
        guard let window = windows.first else { return }
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // set to `false` if you don't want to detect tap during other gestures
    }
}
