//
//  MainTabView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//


import SwiftUI

struct MainTabView: View {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var selectedTab: Tab = .characters

    enum Tab: String, CaseIterable {
        case characters = "Characters"
        case map = "Map"
        case vault = "Vault"
        case cubes = "Dice"
        case artifacts = "History"

        var icon: String {
            switch self {
            case .characters: return "homeIcon"
            case .map: return "mapIcon"
            case .vault: return "vaultIcon"
            case .cubes: return "diceIcon"
            case .artifacts: return "historyIcon"
            }
        }

        var isSystemImage: Bool {
            self != .characters
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack(spacing: 0) {
                    ZStack {
                        switch selectedTab {
                        case .characters:
                            HomeView()
                        case .map:
                            CampaignMapView()
                        case .vault:
                            MastersVaultView()
                        case .cubes:
                            DiceRollerView()
                        case .artifacts:
                            HistoryAndRulesView()
                        }
                    }
                    
                    CustomTabBar(selectedTab: $selectedTab)
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .tint(.accentCol)
            .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
        } else {
            // Fallback on earlier versions
        }
    

    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(tab.icon)
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundStyle((selectedTab == tab ? Color.accentCol : Color.secondaryText))
                        Text(tab.rawValue)
                            .font(.custom(AppFontName.aclonicaRegular, size: 10))
                            .foregroundColor(selectedTab == tab ? Color.accentCol : Color.secondaryText)
                            .padding(.top, 2)
                            .padding(.bottom, size().height > 667 ? 20 : 0)

                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color.cardBackground)
    }
}


#Preview {
    MainTabView()
}


extension View {
    func size() -> CGSize {
        guard let window = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .zero
        }
        return window.screen.bounds.size
    }
}
