//
//  HomeView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingAddCharacterView = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                NewHeaderView(title: "Characters", description: "Create your own characters and explore the bestiary.")
                    .padding(.horizontal, -20)
                
                YourCharactersSection(
                    characters: viewModel.realmCharacters,
                    onAddCharacter: { showingAddCharacterView = true },
                    onDelete: viewModel.deleteCharacter
                )
                
                BestiarySectionView(
                    monsters: viewModel.bestiaryMonsters,
                    isLoading: viewModel.isLoadingMonsters,
                    errorMessage: viewModel.errorMessageMonsters
                )
            }
            .padding(.horizontal)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddCharacterView) {
            if #available(iOS 16.0, *) {
                AddCharacterView()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

#Preview {
    HomeView()
}
