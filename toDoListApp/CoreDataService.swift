//
//  CoreDataService.swift
//  toDoListApp
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import Foundation
import CoreData
import UIKit

class CoreDataService: CoreDataServiceProtocol {

    static let shared = CoreDataService()
    
    var persistentContainer: NSPersistentContainer
    
    // Флаг, чтобы не загружать базу данных несколько раз
    private var isInitialized = false

    private init() {
        self.persistentContainer = NSPersistentContainer(name: "toDoListApp")
    }
    
    func initialize(completion: @escaping () -> Void) {
        // Если уже инициализировались, просто вызываем completion и выходим
        if isInitialized {
            completion()
            return
        }
        
        // Иначе выполняем полную инициализацию
        persistentContainer.loadPersistentStores { [weak self] _, error in
            guard let self = self else { return }
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Устанавливаем флаг, что все готово
            self.isInitialized = true
            // Включаем автоматическое слияние изменений
            self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
            
            completion()
        }
    }

    internal init(container: NSPersistentContainer) {
        self.persistentContainer = container
        self.isInitialized = true
    }

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }


    // MARK: - Public Methods
    
    func toggleTaskCompletion(for taskId: UUID, completion: @escaping (Task?) -> Void) {
        persistentContainer.performBackgroundTask { backgroundContext in
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
            
            do {
                let results = try backgroundContext.fetch(request)
                if let taskEntity = results.first {
                    taskEntity.isCompleted.toggle()
                    try backgroundContext.save()
                    print("Task completion status toggled for ID: \(taskId.uuidString)")
                    
                    // Создаем и возвращаем обновленную задачу
                    let updatedTask = Task(taskEntity: taskEntity)
                    
                    DispatchQueue.main.async {
                        completion(updatedTask)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                print("Failed to toggle task completion: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /// Сохранение всех задач из API в базу данных
    /// обещание - выполнить  код после завершения операции
    func saveInitialTasks(apiTasks: [APITask], completion: @escaping () -> Void) {
        persistentContainer.performBackgroundTask { backgroundContext in
            apiTasks.forEach { apiTask in
                let taskEntity = TaskEntity(context: backgroundContext)
                taskEntity.id = UUID()
                // Сохраняем оригинальный ID с API
                taskEntity.apiId = Int32(apiTask.id)
                
                taskEntity.title = apiTask.todo
                taskEntity.taskDescription = ""
                taskEntity.createdDate = Date()
                taskEntity.isCompleted = apiTask.completed
            }
            
            do {
                try backgroundContext.save()
                print("Background save finished successfully.")
                DispatchQueue.main.async {
                    completion()
                }
            } catch {
                print("Failed to save initial tasks: \(error)")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    /// Получение всех задач из базы данных
    func fetchTasks() -> [Task] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        
        // Если apiId nil (для локальных задач), они будут в конце.
        let primarySortDescriptor = NSSortDescriptor(key: "apiId", ascending: true)
        let secondarySortDescriptor = NSSortDescriptor(key: "createdDate", ascending: false)
        
        request.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
        
        do {
            let taskEntities = try context.fetch(request)
            return taskEntities.map { Task(taskEntity: $0) }
        } catch {
            print("Error fetching tasks from Core Data: \(error)")
            return []
        }
    }
    
    func deleteTask(for taskId: UUID, completion: @escaping () -> Void) {
        persistentContainer.performBackgroundTask { backgroundContext in
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", taskId as CVarArg)
            
            do {
                let results = try backgroundContext.fetch(request)
                if let taskEntityToDelete = results.first {
                    backgroundContext.delete(taskEntityToDelete)
                    try backgroundContext.save()
                    print("Task deleted with ID: \(taskId.uuidString)")
                }
            } catch {
                print("Failed to delete task: \(error)")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func createTask(title: String, description: String, completion: @escaping () -> Void) {
        persistentContainer.performBackgroundTask { backgroundContext in
            let taskEntity = TaskEntity(context: backgroundContext)
            taskEntity.id = UUID()
            taskEntity.title = title
            taskEntity.taskDescription = description
            taskEntity.createdDate = Date()
            taskEntity.isCompleted = false
            
            do {
                try backgroundContext.save()
                print("New task created successfully.")
            } catch {
                print("Failed to create new task: \(error)")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func updateTask(id: UUID, title: String, description: String, completion: @escaping () -> Void) {
        persistentContainer.performBackgroundTask { backgroundContext in
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let results = try backgroundContext.fetch(request)
                if let taskEntity = results.first {
                    taskEntity.title = title
                    taskEntity.taskDescription = description
                    try backgroundContext.save() // Сохраняем в фоновом контексте
                    print("✅ Task updated successfully with ID: \(id.uuidString)")
                }
            } catch {
                print("Failed to update task: \(error)")
            }
            
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
}

