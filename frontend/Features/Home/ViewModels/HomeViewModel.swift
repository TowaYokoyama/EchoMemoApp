//
//  HomeViewModel.swift
//  EchoLogApp
//
//  Created on 2025/11/12
//

import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var memos: [Memo] = []
    @Published var filteredMemos: [Memo] = []
    @Published var selectedTags: Set<String> = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var searchText = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    var allTags: [String] {
        Array(Set(memos.flatMap { $0.tags })).sorted()
    }
    
    init() {
        setupSearchObserver()
    }
    
    private func setupSearchObserver() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.filterMemos()
            }
            .store(in: &cancellables)
        
        $selectedTags
            .sink { [weak self] _ in
                self?.filterMemos()
            }
            .store(in: &cancellables)
    }
    
    func fetchMemos() async {
        isLoading = true
        error = nil
        
        do {
            memos = try await MemoService.shared.fetchMemos()
            filterMemos()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func refreshMemos() async {
        await fetchMemos()
    }
    
    func deleteMemo(_ memo: Memo) async {
        do {
            try await MemoService.shared.deleteMemo(id: memo.id)
            memos.removeAll { $0.id == memo.id }
            filterMemos()
        } catch {
            self.error = error
        }
    }
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func clearFilters() {
        selectedTags.removeAll()
        searchText = ""
    }
    
    private func filterMemos() {
        var result = memos
        
        // タグでフィルタ
        if !selectedTags.isEmpty {
            result = result.filter { memo in
                !Set(memo.tags).isDisjoint(with: selectedTags)
            }
        }
        
        // 検索テキストでフィルタ
        if !searchText.isEmpty {
            result = result.filter { memo in
                memo.title.localizedCaseInsensitiveContains(searchText) ||
                memo.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredMemos = result.sorted { $0.createdAt > $1.createdAt }
    }
    
    func groupedMemos() -> [String: [Memo]] {
        let calendar = Calendar.current
        var grouped: [String: [Memo]] = [:]
        
        for memo in filteredMemos {
            let key: String
            if calendar.isDateInToday(memo.createdAt) {
                key = "今日"
            } else if calendar.isDateInYesterday(memo.createdAt) {
                key = "昨日"
            } else if calendar.isDate(memo.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                key = "今週"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy年M月"
                key = formatter.string(from: memo.createdAt)
            }
            
            grouped[key, default: []].append(memo)
        }
        
        return grouped
    }
}
