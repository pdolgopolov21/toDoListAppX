//
//  TaskListViewModel.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import Foundation

final class TaskListViewModel {
    
    // MARK: - Public Properties

    var tasks: [Task] { return _tasks }
    var filteredTasks: [Task] { return _filteredTasks }
    
    // MARK: - Private Properties
    private var _tasks: [Task] = []
    private var _filteredTasks: [Task] = []
    private var searchText: String?

    // MARK: - Closures for View Controller
    var onDataUpdated: (() -> Void)?
    var onSingleTaskUpdated: ((UUID) -> Void)?
    
    // MARK: - Data Loading
    func fetchTasks() {
        loadTasksFromCoreData()
        clearSearch()
    }
    
    public func refreshTasks() {
        loadTasksFromCoreData()
        reapplyCurrentFilter()
        onDataUpdated?()
    }
    
    // MARK: - Search Logic
    func filterTasks(with searchText: String) {
        self.searchText = searchText
        
        if searchText.isEmpty {
            self._filteredTasks = []
        } else {
            self._filteredTasks = _tasks.filter { task in
                let titleMatch = task.title.lowercased().contains(searchText.lowercased())
                let descriptionMatch = task.taskDescription.lowercased().contains(searchText.lowercased())
                return titleMatch || descriptionMatch
            }
        }
        
        onDataUpdated?()
    }
    
    func clearSearch() {
        self._filteredTasks = []
        self.searchText = nil
        onDataUpdated?()
    }
    
    // MARK: - CRUD Actions
    func toggleTaskCompletion(for taskId: UUID) {
        CoreDataService.shared.toggleTaskCompletion(for: taskId) { [weak self] updatedTask in
            guard let self = self, let updatedTask = updatedTask else { return }
            
            // Обновляем задачу в основном массиве
            if let index = self._tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                self._tasks[index] = updatedTask
            }
            
            // И в отфильтрованном, если она там есть
            if let index = self._filteredTasks.firstIndex(where: { $0.id == updatedTask.id }) {
                self._filteredTasks[index] = updatedTask
            }
            
            // Сообщаем View, что конкретная задача изменилась
            DispatchQueue.main.async {
                self.onSingleTaskUpdated?(updatedTask.id)
            }
        }
    }
    
    func deleteTask(for taskId: UUID) {
        CoreDataService.shared.deleteTask(for: taskId) { [weak self] in
            self?.refreshTasks()
        }
    }
    
    // MARK: - Private Helpers
    private func loadTasksFromCoreData() {
        self._tasks = CoreDataService.shared.fetchTasks()
    }
    
    private func reapplyCurrentFilter() {
        guard let searchText = self.searchText, !searchText.isEmpty else {
            self._filteredTasks = []
            return
        }
        
        self._filteredTasks = _tasks.filter { task in
            let titleMatch = task.title.lowercased().contains(searchText.lowercased())
            let descriptionMatch = task.taskDescription.lowercased().contains(searchText.lowercased())
            return titleMatch || descriptionMatch
        }
    }
    
    // MARK: - Helpers for View
    var isSearching: Bool {
        return !_filteredTasks.isEmpty || (searchText?.isEmpty == false)
    }
    
    var taskCountString: String {
        let count = isSearching ? _filteredTasks.count : _tasks.count
        let ending = count % 10 == 1 && count % 100 != 11 ? "Задача" : (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20) ? "Задачи" : "Задач")
        return "\(count) \(ending)"
    }
    
    func numberOfRowsInSection() -> Int {
        return isSearching ? _filteredTasks.count : _tasks.count
    }
    
    func task(at indexPath: IndexPath) -> Task {
        return isSearching ? _filteredTasks[indexPath.row] : _tasks[indexPath.row]
    }
}
