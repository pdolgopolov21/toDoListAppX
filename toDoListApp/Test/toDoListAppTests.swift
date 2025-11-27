//
//  toDoListAppTests.swift
//  toDoListAppTests
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//
import XCTest
import CoreData
@testable import toDoListAppX

final class ToDoListTests: XCTestCase {

    var coreDataService: CoreDataService!
    var testPersistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {

        guard let modelURL = Bundle.main.url(forResource: "toDoListApp", withExtension: "momd") else {
                fatalError("Error finding model in main bundle")
            }
            guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
                fatalError("Error initializing MOM from: \(modelURL)")
            }

            testPersistentContainer = NSPersistentContainer(name: "toDoListApp", managedObjectModel: managedObjectModel)
            
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            
            testPersistentContainer.persistentStoreDescriptions = [description]
            
            testPersistentContainer.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Failed to load test store: \(error)")
                }
            }
            
            coreDataService = CoreDataService(container: testPersistentContainer)
            
            coreDataService.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        }

    override func tearDownWithError() throws {
        // вызывается после каждого теста.
        coreDataService = nil
        testPersistentContainer = nil
    }
    
    func testCreateAndFetchTask() throws {
        let title = "Test Task"
        let description = "Test Description"
        let expectation = XCTestExpectation(description: "Task creation completion")
        
        coreDataService.createTask(title: title, description: description) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        let tasks = coreDataService.fetchTasks()
        XCTAssertEqual(tasks.count, 1, "Should be one task in the store")
        XCTAssertEqual(tasks.first?.title, title)
        XCTAssertEqual(tasks.first?.taskDescription, description)
        XCTAssertFalse(tasks.first?.isCompleted ?? true, "Task should not be completed")
    }
    
    func testUpdateTask() throws {

        let expectation = XCTestExpectation(description: "Task update completion")
        coreDataService.createTask(title: "Old Title", description: "Old Desc") {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let taskToUpdate = coreDataService.fetchTasks().first!
        let newTitle = "New Title"
        let newDesc = "New Desc"
        let updateExpectation = XCTestExpectation(description: "Task update completion")
        
        // Act
        coreDataService.updateTask(id: taskToUpdate.id, title: newTitle, description: newDesc) {
            updateExpectation.fulfill()
        }
        wait(for: [updateExpectation], timeout: 1.0)
        
        // Assert
        let updatedTasks = coreDataService.fetchTasks()
        XCTAssertEqual(updatedTasks.count, 1)
        XCTAssertEqual(updatedTasks.first?.title, newTitle)
        XCTAssertEqual(updatedTasks.first?.taskDescription, newDesc)
    }
    
   
    
    func testDeleteTask() throws {
        // Arrange
        let expectation = XCTestExpectation(description: "Task creation for deletion")
        coreDataService.createTask(title: "To Delete", description: "") {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let taskToDelete = coreDataService.fetchTasks().first!
        let deleteExpectation = XCTestExpectation(description: "Task deletion completion")
        XCTAssertEqual(coreDataService.fetchTasks().count, 1)
        
        // Act
        coreDataService.deleteTask(for: taskToDelete.id) {
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(coreDataService.fetchTasks().count, 0, "Task should be deleted")
    }
}
