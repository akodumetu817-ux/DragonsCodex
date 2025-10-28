//
//  DiceView.swift
//  Melbe
//
//  Created by D K on 09.05.2025.
//

import SwiftUI
import Combine

enum DiceType: Int, CaseIterable, Identifiable {
    case d4 = 4
    case d6 = 6
    case d8 = 8
    case d10 = 10
    case d12 = 12
    case d20 = 20
    case d100 = 100

    var id: Int { self.rawValue }

    var displayName: String {
        "d\(self.rawValue)"
    }

    var iconName: String {
        switch self {
        case .d4: return "triangle.fill"
        case .d6: return "square.fill"
        case .d8: return "diamond.fill"
        case .d10: return "pentagon.fill"
        case .d12: return "hexagon.fill"
        case .d20: return "star.fill"
        case .d100: return "percent"
        }
    }
}

@MainActor
class DiceRollerViewModel: ObservableObject {
    @Published var selectedDie: DiceType = .d8
    @Published var quantity: Int = 2
    @Published var autoSumResults: Bool = true
    @Published var showAnimation: Bool = true

    @Published var individualResults: [Int] = []
    @Published var totalResult: Int = 0
    
    @Published var animatedResults: [String] = []
    @Published var resultsReady: Bool = false
    private var animationTimer: Timer?
    private var currentAnimatingIndex: Int = 0

    let minQuantity = 1
    let maxQuantity = 20

    var rollButtonText: String {
        "Roll \(quantity)\(selectedDie.displayName)"
    }

    func incrementQuantity() {
        if quantity < maxQuantity {
            quantity += 1
        }
    }

    func decrementQuantity() {
        if quantity > minQuantity {
            quantity -= 1
        }
    }

    func rollDice() {
        individualResults = []
        totalResult = 0
        resultsReady = false
        animatedResults = Array(repeating: "?", count: quantity)
        
        var rolls: [Int] = []
        for _ in 0..<quantity {
            rolls.append(Int.random(in: 1...selectedDie.rawValue))
        }
        individualResults = rolls
        
        if autoSumResults {
            totalResult = individualResults.reduce(0, +)
        }

        if showAnimation && quantity > 0 {
            currentAnimatingIndex = 0
            animationTimer?.invalidate()
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                if self.currentAnimatingIndex < self.quantity {
                    self.animatedResults[self.currentAnimatingIndex] = String(self.individualResults[self.currentAnimatingIndex])
                    self.currentAnimatingIndex += 1
                } else {
                    timer.invalidate()
                    self.resultsReady = true
                }
            }
        } else {
            animatedResults = individualResults.map { String($0) }
            resultsReady = true
        }
    }
}

struct DiceRollerView: View {
    @StateObject private var viewModel = DiceRollerViewModel()
    private let fontName = "Aclonica-Regular"
    
    private let screenBackgroundColor = Color.appBackground
    private let cardBackgroundColor = Color(hex: "495057")
    private let accentColor = Color(hex: "0075a5")
    private let buttonTextColor = Color.black
    private let defaultTextColor = Color.white

    var body: some View {
        ZStack {
            screenBackgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                NewHeaderView(title: "Dice", description: "Throw virtual dice and watch the result.")
                    .padding(.horizontal, 0)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Select Dice
                        Text("Select Dice")
                            .font(Font.custom(fontName, size: 18))
                            .foregroundColor(defaultTextColor)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(DiceType.allCases) { die in
                                DiceButton(die: die,
                                           isSelected: viewModel.selectedDie == die,
                                           fontName: fontName,
                                           accentColor: accentColor,
                                           cardBackgroundColor: cardBackgroundColor,
                                           buttonTextColor: buttonTextColor,
                                           defaultTextColor: defaultTextColor) {
                                    viewModel.selectedDie = die
                                }
                            }
                        }

                        // MARK: - Quantity
                        Text("Quantity")
                            .font(Font.custom(fontName, size: 18))
                            .foregroundColor(defaultTextColor)
                        QuantityControl(quantity: $viewModel.quantity,
                                        fontName: fontName,
                                        increment: viewModel.incrementQuantity,
                                        decrement: viewModel.decrementQuantity,
                                        cardBackgroundColor: cardBackgroundColor,
                                        defaultTextColor: defaultTextColor)

                        // MARK: - Settings
                        SettingsToggleRow(title: "Auto-sum results",
                                          isOn: $viewModel.autoSumResults,
                                          fontName: fontName,
                                          accentColor: accentColor,
                                          defaultTextColor: defaultTextColor)
                        
                        SettingsToggleRow(title: "Show animation",
                                          isOn: $viewModel.showAnimation,
                                          fontName: fontName,
                                          accentColor: accentColor,
                                          defaultTextColor: defaultTextColor)
                        
                        // MARK: - Roll Button
                        Button(action: viewModel.rollDice) {
                            HStack {
                                Image(systemName: "dice.fill")
                                Text(viewModel.rollButtonText)
                            }
                            .font(Font.custom(fontName, size: 18))
                            .foregroundColor(buttonTextColor)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(accentColor)
                            .cornerRadius(10)
                        }
                        .padding(.top, 10)

                        // MARK: - Results
                        if !viewModel.individualResults.isEmpty && viewModel.resultsReady || (!viewModel.showAnimation && !viewModel.individualResults.isEmpty) {
                            ResultsDisplay(results: viewModel.showAnimation ? viewModel.animatedResults : viewModel.individualResults.map { String($0) },
                                           total: viewModel.autoSumResults ? viewModel.totalResult : nil,
                                           fontName: fontName,
                                           cardBackgroundColor: cardBackgroundColor,
                                           accentColor: accentColor)
                        } else if viewModel.showAnimation && !viewModel.animatedResults.isEmpty && !viewModel.resultsReady {
                            ResultsDisplay(results: viewModel.animatedResults,
                                           total: nil,
                                           fontName: fontName,
                                           cardBackgroundColor: cardBackgroundColor,
                                           accentColor: accentColor,
                                           isAnimating: true)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .environment(\.font, Font.custom(fontName, size: 14))
    }
}

struct DiceButton: View {
    let die: DiceType
    let isSelected: Bool
    let fontName: String
    let accentColor: Color
    let cardBackgroundColor: Color
    let buttonTextColor: Color
    let defaultTextColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: die.iconName)
                    .font(.title2)
                    .frame(height: 25)
                Text(die.displayName)
                    .font(Font.custom(fontName, size: 14))
            }
            .foregroundColor(isSelected ? buttonTextColor : defaultTextColor)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(isSelected ? accentColor : cardBackgroundColor)
            .cornerRadius(10)
        }
    }
}

struct QuantityControl: View {
    @Binding var quantity: Int
    let fontName: String
    let increment: () -> Void
    let decrement: () -> Void
    let cardBackgroundColor: Color
    let defaultTextColor: Color

    var body: some View {
        HStack(spacing: 0) {
            Button(action: decrement) {
                Image(systemName: "minus")
                    .frame(width: 50, height: 50)
            }
            .disabled(quantity <= 1)

            Spacer()
            Text("\(quantity)")
                .font(Font.custom(fontName, size: 20))
            Spacer()

            Button(action: increment) {
                Image(systemName: "plus")
                    .frame(width: 50, height: 50)
            }
            .disabled(quantity >= 20)
        }
        .foregroundColor(defaultTextColor)
        .background(cardBackgroundColor)
        .cornerRadius(10)
        .frame(height: 50)
    }
}

struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let fontName: String
    let accentColor: Color
    let defaultTextColor: Color

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(Font.custom(fontName, size: 16))
                .foregroundColor(defaultTextColor)
        }
        .tint(accentColor)
    }
}

struct ResultsDisplay: View {
    let results: [String]
    let total: Int?
    let fontName: String
    let cardBackgroundColor: Color
    let accentColor: Color
    var isAnimating: Bool = false

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 50, maximum: 60))]
    }

    var body: some View {
        VStack(spacing: 15) {
            if !results.isEmpty {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(results.indices, id: \.self) { index in
                        Text(results[index])
                            .font(Font.custom(fontName, size: 24).bold())
                            .foregroundColor(accentColor)
                            .frame(width: 55, height: 55)
                            .background(cardBackgroundColor)
                            .cornerRadius(8)
                            .transition(.scale.combined(with: .opacity))
                            .id("\(results[index])-\(index)-\(isAnimating)")
                    }
                }
                .animation(isAnimating ? .default : .none, value: results)
            }

            if let total = total {
                Text("Total: ")
                    .font(Font.custom(fontName, size: 20))
                    .foregroundColor(Color.white)
                + Text("\(total)")
                    .font(Font.custom(fontName, size: 22).bold())
                    .foregroundColor(accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
}


struct DiceRollerView_Previews: PreviewProvider {
    static var previews: some View {
        DiceRollerView()
            .preferredColorScheme(.dark)
    }
}
