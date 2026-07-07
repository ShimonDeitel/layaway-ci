import XCTest

final class LayawayUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
    }

    func testLaunchShowsSeededPlans() {
        XCTAssertTrue(app.staticTexts["Couch"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["iPhone"].waitForExistence(timeout: 5))
    }

    func testAddPlanFlow() {
        app.buttons["addPlanButton"].tap()

        let nameField = app.textFields["planNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Mattress")

        let totalField = app.textFields["planTotalField"]
        totalField.tap()
        totalField.typeText("600")

        let saveButton = app.buttons["savePlanButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Mattress"].waitForExistence(timeout: 5))
    }

    func testKeyboardDismissOnTapOutside() {
        app.buttons["addPlanButton"].tap()
        let nameField = app.textFields["planNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5))

        app.staticTexts["Plan"].tap()

        let predicate = NSPredicate(format: "count == 0")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: app.keyboards)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        XCTAssertEqual(result, .completed, "Keyboard should dismiss after tapping outside the text field")
    }

    func testTogglePaidUpdatesPunchCard() {
        let showButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'installments'")).firstMatch
        XCTAssertTrue(showButton.waitForExistence(timeout: 5))
        showButton.tap()

        let toggleButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'toggleInstallment_'"))
        XCTAssertTrue(toggleButtons.firstMatch.waitForExistence(timeout: 5))
        toggleButtons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Layaway"].waitForExistence(timeout: 5))
    }
}
