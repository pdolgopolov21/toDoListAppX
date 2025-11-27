//
//  AddEditTaskModel.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 27.11.2025.
//

import Foundation

class AddEditTaskModel {
    
    // MARK: - Properties
    
    private(set) var taskToEdit: Task?
    
    var isEditMode: Bool {
        return taskToEdit != nil
    }
    
    private var currentTitle: String = ""
    private var currentDescription: String = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    // 2. Храним сервис как свойство с типом протокола
    private let dataService: CoreDataServiceProtocol
    
    // MARK: - Initialization
    
    // 3. Внедряем зависимость через инициализатор
    init(taskToEdit: Task?, dataService: CoreDataServiceProtocol) {
        self.taskToEdit = taskToEdit
        self.dataService = dataService
    }
    
    // MARK: - Public Methods
    
    /// Обновляет модель данными из UI
    func update(title: String, description: String) {
        self.currentTitle = title
        self.currentDescription = description
    }
    
    /// Выполняет сохранение или удаление задачи на основе текущего состояния
    func saveOrDelete() {
        let titleIsEmpty = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let descriptionIsNotEmpty = !currentDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        var finalTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if titleIsEmpty && descriptionIsNotEmpty {
            finalTitle = getWords(from: currentDescription, maxCount: 2)
        }
        
        if isEditMode {
            if finalTitle.isEmpty {
                print("Заголовок и описание пусты. Удаляем задачу.")
                guard let taskId = taskToEdit?.id else { return }
                // Используем внедренный сервис и тд
                dataService.deleteTask(for: taskId) {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .taskDidUpdate, object: nil)
                    }
                }
                return
            } else {
                updateTask(title: finalTitle, description: currentDescription)
            }
        } else {
            guard !finalTitle.isEmpty else {
                print("Заголовок пуст, задача не будет создана.")
                return
            }
            createTask(title: finalTitle, description: currentDescription)
        }
    }
    
    /// Возвращает начальные данные для заполнения UI
    func getInitialData() -> (title: String?, placeholder: String, description: String?, date: String) {
        var title: String?
        var description: String?
        
        if isEditMode {
            if let taskTitle = taskToEdit?.title, !taskTitle.isEmpty {
                title = taskTitle
            } else if let taskDescription = taskToEdit?.taskDescription, !taskDescription.isEmpty {
                title = getWords(from: taskDescription, maxCount: 2)
            }
            
            if let taskDescription = taskToEdit?.taskDescription, !taskDescription.isEmpty {
                description = taskDescription
            }
        }
        
        let placeholderText = "Новая задача"
        let dateString = dateFormatter.string(from: taskToEdit?.createdDate ?? Date())
        
        return (title: title, placeholder: placeholderText, description: description, date: dateString)
    }
    
    // MARK: - Private Methods
    
    private func createTask(title: String, description: String) {
        dataService.createTask(title: title, description: description) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .taskDidUpdate, object: nil)
            }
        }
    }
    
    private func updateTask(title: String, description: String) {
        guard let taskId = taskToEdit?.id else { return }

        dataService.updateTask(id: taskId, title: title, description: description) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .taskDidUpdate, object: nil)
            }
        }
    }
    
    private func getWords(from string: String, maxCount: Int) -> String {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = trimmedString.components(separatedBy: .whitespacesAndNewlines)
        let selectedWords = words.prefix(maxCount)
        return selectedWords.joined(separator: " ")
    }
}
