//
//  AllMonstersView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI

import SwiftUI

@available(iOS 16.0, *)
struct AllMonstersView: View {
    @StateObject private var viewModel = AllMonstersViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryText)
                TextField("Search Monsters...", text: $viewModel.searchText)
                    .font(.custom(AppFontName.aclonicaRegular, size: 16))
                    .foregroundColor(.primaryText)
                    .tint(Color.accentCol)
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondaryText)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top)

            if viewModel.displayedMonsters.isEmpty && viewModel.isLoadingPage && viewModel.allMonsterListItems.isEmpty {
                InitialLoadingView()
            } else if let errorMessage = viewModel.errorMessage, viewModel.displayedMonsters.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await viewModel.refreshData() }
                }
            } else if viewModel.filteredMonsters.isEmpty && !viewModel.searchText.isEmpty && !viewModel.isLoadingPage {
                 NoSearchResultsView()
            }
            else {
                List {
                    ForEach(viewModel.filteredMonsters) { monster in
                        ZStack {
                            MonsterCardView(monster: monster)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .padding(.vertical, 6)
                                .padding(.horizontal)
                                .background(Color.appBackground)
                            
                            NavigationLink(destination: MonsterDetailView(monster: monster)) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .onAppear {
                            if monster.id == viewModel.displayedMonsters.last?.id &&
                               viewModel.canLoadMorePages &&
                               viewModel.searchText.isEmpty &&
                               !viewModel.isLoadingPage {
                                
                                print("AllMonstersView: Reached end of list, loading next page.")
                                Task {
                                    await viewModel.loadNextPageOfMonsterDetails()
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.appBackground)

                    if viewModel.isLoadingPage && !viewModel.displayedMonsters.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.appBackground)
                    }
                    
                    if !viewModel.canLoadMorePages && !viewModel.displayedMonsters.isEmpty && viewModel.searchText.isEmpty {
                        Text("All monsters loaded.")
                            .font(.custom(AppFontName.aclonicaRegular, size: 14))
                            .foregroundColor(.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.appBackground)
                    }
                }
                .listStyle(.plain)
                .background(Color.appBackground)
                .refreshable {
                    await viewModel.refreshData()
                }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("All Monsters")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct InitialLoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .padding(.top, 50)
            Text("Loading monster encyclopedia...")
                .font(.custom(AppFontName.aclonicaRegular, size: 16))
                .foregroundColor(.secondaryText)
                .padding(.top)
        }
        .frame(maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.levelRed)
            Text(message)
                .font(.custom(AppFontName.aclonicaRegular, size: 16))
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                retryAction()
            } label: {
                Text("Try Again")
                    .font(.custom(AppFontName.aclonicaRegular, size: 16))
                    .foregroundColor(Color.buttonTextOnYellow)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentCol)
                    .cornerRadius(8)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct NoSearchResultsView: View {
    var body: some View {
        VStack {
            Image(systemName: "binoculars.fill")
                .font(.largeTitle)
                .foregroundColor(.secondaryText)
                .padding(.bottom, 5)
            Text("No monsters match your search.")
                .font(.custom(AppFontName.aclonicaRegular, size: 16))
                .foregroundColor(.secondaryText)
        }
        .frame(maxHeight: .infinity)
    }
}

