//
//  CoreDataServiceProtocol.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 25.11.2025.
//

import Foundation

protocol CoreDataServiceProtocol {
    func fetchTasks() -> [Task]
    func createTask(title: String, description: String, completion: @escaping () -> Void)
    func updateTask(id: UUID, title: String, description: String, completion: @escaping () -> Void)
    func deleteTask(for taskId: UUID, completion: @escaping () -> Void)
    func toggleTaskCompletion(for taskId: UUID, completion: @escaping (Task?) -> Void)
}
