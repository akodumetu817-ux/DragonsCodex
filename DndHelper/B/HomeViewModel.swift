//
//  HomeViewModel.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//
// File: HomeViewModel.swift (или как он у тебя называется)
import SwiftUI
import Combine
import RealmSwift // Добавляем импорт RealmSwift

@MainActor
class HomeViewModel: ObservableObject {
    // Персонажи из Realm
    @Published var realmCharacters: [CharacterObject] = []
    private var charactersResults: Results<CharacterObject>?
    private var charactersNotificationToken: NotificationToken?

    // Бестиарий (оставляем как было)
    @Published var bestiaryMonsters: [MonsterDetail] = []
    @Published var isLoadingMonsters: Bool = false
    @Published var errorMessageMonsters: String? = nil

    private var apiService = APIService.shared

    init() {
        setupCharacterObserver()
        Task {
            await loadPopularMonstersFromAPI()
        }
    }

    // MARK: - Character Logic (Realm)
    private func setupCharacterObserver() {
        charactersResults = RealmManager.shared.fetchCharacters()
        
        charactersNotificationToken = charactersResults?.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial(let results):
                print("HomeViewModel: Initial characters loaded from Realm: \(results.count)")
                self.realmCharacters = Array(results)
            case .update(let results, _, _, _):
                print("HomeViewModel: Characters updated in Realm: \(results.count)")
                self.realmCharacters = Array(results)
            case .error(let error):
                print("HomeViewModel: Error observing Realm characters: \(error)")
            }
        }
    }
    
    func deleteCharacter(at offsets: IndexSet) {
        offsets.forEach { index in
            if realmCharacters.indices.contains(index) {
                let characterToDelete = realmCharacters[index]
                RealmManager.shared.deleteCharacter(id: characterToDelete.id)
            }
        }
    }
    
    deinit {
        charactersNotificationToken?.invalidate()
        print("HomeViewModel deinitialized, notification token invalidated.")
    }

    // MARK: - Bestiary Logic (API)
    func loadPopularMonstersFromAPI() async {
        print("HomeViewModel: Starting to load popular monsters from API...")
        guard bestiaryMonsters.isEmpty else {
             print("HomeViewModel: Popular monsters already loaded.")
             return
        }

        isLoadingMonsters = true
        errorMessageMonsters = nil
        
        let listResult = await apiService.fetchAllMonstersList()
        
        switch listResult {
        case .success(let monsterListItems):
            print("HomeViewModel: Successfully fetched \(monsterListItems.count) monster list items for bestiary.")
            var fetchedDetails: [MonsterDetail] = []
            let itemsToFetch = Array(monsterListItems.prefix(4))

            await withTaskGroup(of: Result<MonsterDetail, NetworkError>?.self) { group in
                for item in itemsToFetch {
                    guard let itemURL = item.url else { continue }
                    group.addTask { [weak self] in
                        guard self != nil else { return nil } // Проверка self
                        return await self!.apiService.fetchMonsterDetail(from: itemURL)
                    }
                }
                
                for await result in group {
                    if let result = result {
                        switch result {
                        case .success(let detail):
                            fetchedDetails.append(detail)
                        case .failure(let error):
                            if !(error is CancellationError) {
                                print("HomeViewModel: Failed to fetch a popular monster detail: \(error)")
                                self.errorMessageMonsters = "Error loading some monster details."
                            }
                        }
                    }
                }
            }
            self.bestiaryMonsters = fetchedDetails.sorted { ($0.name ?? "") < ($1.name ?? "") }
            print("HomeViewModel: Finished loading popular monsters. Total: \(self.bestiaryMonsters.count)")
            
        case .failure(let error):
             if !(error is CancellationError) {
                print("HomeViewModel: Failed to fetch monster list for bestiary: \(error)")
                self.errorMessageMonsters = "Error loading monster list: \(error.localizedDescription)"
            }
        }
        isLoadingMonsters = false
    }
}

struct CharacterModel: Identifiable {
    let id = UUID()
    let name: String
    let raceClass: String
    let avatarImageName: String
    let placeholderColor: Color
}

