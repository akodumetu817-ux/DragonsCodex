//
//  AllMonstersViewModel.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//
import SwiftUI
import Combine
import SwiftUI
import Combine

@MainActor
class AllMonstersViewModel: ObservableObject {
    @Published var displayedMonsters: [MonsterDetail] = []
    @Published var isLoadingPage: Bool = false
    @Published var canLoadMorePages: Bool = true
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""

     var apiService = APIService.shared
     var allMonsterListItems: [MonsterListItem] = []
     var loadedDetailsCount: Int = 0
     var currentPageToFetchDetailsFor: Int = 0
     let detailsPageSize: Int = 20

    private var currentLoadingTask: Task<Void, Never>?

    var filteredMonsters: [MonsterDetail] {
        if searchText.isEmpty {
            return displayedMonsters
        } else {
            return displayedMonsters.filter {
                ($0.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.type ?? "").localizedCaseInsensitiveContains(searchText)
            }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
    }

    init() {
        Task {
            await loadInitialMonsterList()
        }
    }
    
    deinit {
        print("AllMonstersViewModel: deinit, cancelling current loading task.")
        currentLoadingTask?.cancel()
    }

    private func loadInitialMonsterList() async {
        currentLoadingTask?.cancel()
        
        currentLoadingTask = Task {
            do {
                try Task.checkCancellation()
            } catch {
                print("AllMonstersViewModel: InitialMonsterList task was cancelled before starting.")
                if self.isLoadingPage { self.isLoadingPage = false }
                return
            }

            guard self.allMonsterListItems.isEmpty || self.displayedMonsters.isEmpty else {
                 print("AllMonstersViewModel: Initial list likely already processed or being processed.")
                 return
            }

            print("AllMonstersViewModel: Starting to load all monster list items (indices)...")
            self.isLoadingPage = true
            self.errorMessage = nil
            
            let listResult = await apiService.fetchAllMonstersList()

            do {
                try Task.checkCancellation()
            } catch {
                print("AllMonstersViewModel: InitialMonsterList task cancelled after fetching list items.")
                self.isLoadingPage = false
                return
            }
            
            switch listResult {
            case .success(let monsterListItems):
                print("AllMonstersViewModel: Successfully fetched \(monsterListItems.count) monster list item indices.")
                self.allMonsterListItems = monsterListItems
                self.canLoadMorePages = !monsterListItems.isEmpty
                self.currentPageToFetchDetailsFor = 0
                self.loadedDetailsCount = 0
                self.displayedMonsters.removeAll()
                
                await self.loadNextPageOfMonsterDetails(isPartOfInitialLoad: true)
                
            case .failure(let error):
                print("AllMonstersViewModel: Failed to fetch monster list indices: \(error)")
                if !(error is CancellationError) {
                    self.errorMessage = "Error loading monster list: \(error.localizedDescription)"
                }
                self.isLoadingPage = false
                self.canLoadMorePages = false
            }
        }
    }

    func loadNextPageOfMonsterDetails(isPartOfInitialLoad: Bool = false) async {
        guard !isLoadingPage || isPartOfInitialLoad else {
            if isLoadingPage { print("AllMonstersViewModel: Already loading a page (and not initial).") }
            return
        }
        
        guard canLoadMorePages else {
            if !canLoadMorePages { print("AllMonstersViewModel: No more pages to load.") }
            return
        }

        if Task.isCancelled {
             print("AllMonstersViewModel: loadNextPage task or its parent task was cancelled before starting page load.")
             
             if !isPartOfInitialLoad && isLoadingPage {
                 self.isLoadingPage = false
             }
             return
        }

        if !isPartOfInitialLoad {
             self.isLoadingPage = true
             self.errorMessage = nil
        } else if !self.isLoadingPage {
            self.isLoadingPage = true
        }


        let startIndex = self.currentPageToFetchDetailsFor * self.detailsPageSize
        let endIndex = min(startIndex + self.detailsPageSize, self.allMonsterListItems.count)

        guard startIndex < endIndex else {
            print("AllMonstersViewModel: No more monster items to fetch details for.")
            self.canLoadMorePages = false
            self.isLoadingPage = false
            return
        }

        let itemsToFetchForThisPage = Array(self.allMonsterListItems[startIndex..<endIndex])
        print("AllMonstersViewModel: Starting to fetch details for page \(self.currentPageToFetchDetailsFor + 1) (\(itemsToFetchForThisPage.count) monsters: \(startIndex) to \(endIndex-1)).")

        var newDetailsForPage: [MonsterDetail] = []
        let currentApiService = self.apiService

        await withTaskGroup(of: Result<MonsterDetail, NetworkError>?.self) { [weak self] group in
            guard let strongSelf = self else {
                print("AllMonstersViewModel: strongSelf (ViewModel) is nil at start of TaskGroup for page.")
                return
            }
            for item in itemsToFetchForThisPage {
                if Task.isCancelled { break }
                guard let itemURL = item.url else { continue }
                group.addTask {
                    if Task.isCancelled { return nil }
                    return await currentApiService.fetchMonsterDetail(from: itemURL)
                }
            }
            
            for await result in group {
                if Task.isCancelled {
                    print("AllMonstersViewModel: TaskGroup cancelled while collecting results.")
                    break
                }
                guard let strongSelf = self else {
                    print("AllMonstersViewModel: strongSelf (ViewModel) is nil while processing results for page, skipping result.")
                    break
                }
                 if let result = result {
                    switch result {
                    case .success(let detail):
                        newDetailsForPage.append(detail)
                    case .failure(let error):
                        if !(error is CancellationError) {
                             print("AllMonstersViewModel: Failed to fetch/process monster detail for page: \(error) for item \(itemsToFetchForThisPage.first(where: { resItem in result.isFailureMatchingItem(resItem.url, error: error as? NetworkError) })?.name ?? "unknown")")
                        }
                    }
                }
            }
        }
        
        if Task.isCancelled {
            print("AllMonstersViewModel: loadNextPage task cancelled after TaskGroup.")
            self.isLoadingPage = false
            return
        }

    

        if !newDetailsForPage.isEmpty {
            var combined = self.displayedMonsters + newDetailsForPage
            combined.sort { ($0.name ?? "") < ($1.name ?? "") }
            self.displayedMonsters = combined
            
            self.loadedDetailsCount += newDetailsForPage.count
            print("AllMonstersViewModel: Page \(self.currentPageToFetchDetailsFor + 1) loaded. Added \(newDetailsForPage.count) new details. Total displayed: \(self.displayedMonsters.count). Total details loaded: \(self.loadedDetailsCount)")
            self.currentPageToFetchDetailsFor += 1
        } else {
            if startIndex < self.allMonsterListItems.count && self.allMonsterListItems.count > 0 {
                print("AllMonstersViewModel: No new details loaded for page \(self.currentPageToFetchDetailsFor + 1), though more items exist in list. Possible API errors for all items on this page.")
            } else {
                print("AllMonstersViewModel: No new details loaded for page \(self.currentPageToFetchDetailsFor + 1).")
            }
        }

        self.canLoadMorePages = self.loadedDetailsCount < self.allMonsterListItems.count
        if !self.canLoadMorePages {
             print("AllMonstersViewModel: All monster details loaded. Total: \(self.loadedDetailsCount)")
        }
        self.isLoadingPage = false
    }

    func refreshData() async {
        print("AllMonstersViewModel: Refreshing data...")
        currentLoadingTask?.cancel()
        
        self.allMonsterListItems.removeAll()
        self.loadedDetailsCount = 0
        self.currentPageToFetchDetailsFor = 0
        self.canLoadMorePages = true
        self.errorMessage = nil
        
        await loadInitialMonsterList()
    }
}

extension Result where Failure == NetworkError {
    func isFailureMatchingItem(_ itemURL: String?, error: NetworkError?) -> Bool {
        guard let itemURL = itemURL, let nsError = error as NSError? else { return false }
        return nsError.localizedDescription.contains(itemURL)
    }
}
