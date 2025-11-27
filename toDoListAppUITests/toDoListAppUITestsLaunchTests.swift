// toDoListAppUITestsLaunchTests.swift
//
//  Created by Pavel Dolgopolov on 24.11.2025.
//

import XCTest
import Foundation

final class toDoListAppUITestsLaunchTests: XCTestCase {

    private var currentConfiguration: String = ""

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    // MARK: - Вспомогательные функции

    private func takeScreenshot(name: String, app: XCUIApplication) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name)_\(currentConfiguration)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func navigateToAddEditScreen(app: XCUIApplication) {
        let addButton = app.buttons["addButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Кнопка '+' не найдена")
        addButton.tap()
        
        let titleTextField = app.textFields["titleTextField"]
        XCTAssertTrue(titleTextField.waitForExistence(timeout: 3), "Поле для заголовка не найдено")
    }

    // MARK: - Тест-оркестратор

    @MainActor
    func testAllScreenshots() throws {
        let configurations = [
            (name: "TaskList", needsNavigation: false),
            (name: "AddEdit", needsNavigation: true)
        ]
        
        let modes = [
            (orientation: "Portrait", appearance: "Light"),
            (orientation: "Landscape", appearance: "Dark")
        ]

        for config in configurations {
            for mode in modes {
                currentConfiguration = "\(mode.orientation)_\(mode.appearance)"
                
                let app = XCUIApplication()
                var launchArguments: [String] = ["UI_TESTING"]
                
                if mode.orientation == "Landscape" {
                    launchArguments.append(contentsOf: ["-orientation", "Landscape"])
                }
                if mode.appearance == "Dark" {
                    launchArguments.append(contentsOf: ["-AppleInterfaceStyle", "Dark"])
                }
                app.launchArguments = launchArguments
                app.launch()

                // Ждем появления главного экрана
                let taskCountLabel = app.staticTexts["taskCountLabel"]
                XCTAssertTrue(taskCountLabel.waitForExistence(timeout: 5), "Главный экран не загрузился")

                if config.needsNavigation {
                    navigateToAddEditScreen(app: app)
                }
                
                // Фиксированная задержка, чтобы UI гарантированно успел отрисоваться
                sleep(2)

                takeScreenshot(name: config.name, app: app)
                
                app.terminate()
            }
        }
    }
}
