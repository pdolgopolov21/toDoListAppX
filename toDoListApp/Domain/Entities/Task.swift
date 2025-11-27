//
//  Task.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import Foundation

struct Task: Identifiable {
    let id: UUID
    var apiId: Int32? // для хранения ID с API
    var title: String
    var taskDescription: String
    let createdDate: Date
    var isCompleted: Bool
    
    //  инициализатор для локальных задач
    init(title: String, taskDescription: String) {
        self.id = UUID()
        self.apiId = nil // У локальной задачи нет apiId
        self.title = title
        self.taskDescription = taskDescription
        self.createdDate = Date()
        self.isCompleted = false
    }
    
    //  для создания из CoreData объекта
    init(taskEntity: TaskEntity) {
        self.id = taskEntity.id ?? UUID()
        self.apiId = taskEntity.apiId // получаем apiId из Entity
        self.title = taskEntity.title ?? ""
        self.taskDescription = taskEntity.taskDescription ?? ""
        self.createdDate = taskEntity.createdDate ?? Date()
        self.isCompleted = taskEntity.isCompleted
    }
}
