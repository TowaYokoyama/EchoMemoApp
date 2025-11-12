//
//  SearchViewModel.swift
//  EchoLogApp
//
//  Created on 2025/11/12
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Memo] = []
    @Published var isSearching = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchObserver()
    }
    
    private func setupSearchObserver() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.search(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        error = nil
        
        do {
            searchResults = try await MemoService.shared.searchMemos(query: query)
        } catch {
            self.error = error
            searchResults = []
        }
        
        isSearching = false
    }
}
