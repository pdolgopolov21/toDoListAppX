// toDoListAppUITests.swift
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import XCTest

final class toDoListAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        app.terminate()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // Наш первый реальный тест
    func testAddNewTask() throws {
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        // 1. Ждем, пока главный экран загрузится.
        let taskCountLabel = app.staticTexts["taskCountLabel"]
        XCTAssertTrue(taskCountLabel.waitForExistence(timeout: 5), "Главный экран не загрузился или счетчик задач не найден")

        // Act (Действие)
        // 2. Находим и нажимаем кнопку "+".
        let addButton = app.buttons["addButton"]
        XCTAssertTrue(addButton.exists, "Кнопка добавления не найдена")
        addButton.tap()

        // 3. Теперь мы на экране редактирования. Заполняем поля.
        let titleTextField = app.textFields["titleTextField"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 3), "Экран редактирования не загрузился или поле для заголовка не найдено")
        titleTextField.tap()
        titleTextField.typeText("Задача из UI теста")

        let descriptionTextView = app.textViews["descriptionTextView"]
        XCTAssertTrue(descriptionTextView.exists, "Поле для описания не найдено")
        descriptionTextView.tap()
        descriptionTextView.typeText("Это описание было создано автоматически.")

        // 4. Возвращаемся на главный экран, чтобы сохранить задачу.
        let backButton = app.navigationBars.buttons["Задачи"]
        XCTAssertTrue(backButton.exists, "Кнопка 'Назад' не найдена")
        backButton.tap()

        // Assert (Проверка)
        // 5. Проверяем, что мы вернулись на главный экран и задача появилась.
        let newTaskTitle = app.staticTexts["Задача из UI теста"]
        XCTAssertTrue(newTaskTitle.waitForExistence(timeout: 3), "Новая задача не появилась в списке")

        // 6. Проверяем, что счетчик задач обновился.
        let updatedTaskCountLabel = app.staticTexts["taskCountLabel"]
        XCTAssertTrue(updatedTaskCountLabel.exists, "Счетчик задач не обновлен")
        // Можно дополнительно проверить текст, если нужно
//        XCTAssertEqual(updatedTaskCountLabel.label as? String, "1 Задача", "Неверное количество задач")
    }
    
    // Тест производительности запуска
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // Создаем НОВЫЙ, чистый экземпляр приложения для теста производительности
            let performanceApp = XCUIApplication()
            
            // Устанавливаем аргументы, чтобы НЕ загружать данные из сети для чистого замера
            performanceApp.launchArguments = ["UI_TESTING"]
            
            // Используем этот новый экземпляр в блоке measure
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                performanceApp.launch()
            }
        }
    }
}
