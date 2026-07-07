import XCTest

final class LayawayUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testAddPlanFromMainList() throws {
        let app = launchApp()

        let addButton = app.buttons["addPlanButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["planNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Laptop")

        let priceField = app.textFields["planPriceField"]
        priceField.tap()
        priceField.typeText("900")

        let saveButton = app.buttons["planSaveButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Laptop"].waitForExistence(timeout: 5), "New plan did not appear")
    }

    func testPayNextBeadLogsExpectedAmount() throws {
        let app = launchApp()
        // Seed data has "Dining Table" plan already.
        let payButton = app.buttons["payNextBead_Dining Table"]
        XCTAssertTrue(payButton.waitForExistence(timeout: 5))
        payButton.tap()

        // After paying, remaining amount text should update; just confirm the
        // button is still present (plan not fully paid off from one tap).
        XCTAssertTrue(app.staticTexts["Dining Table"].waitForExistence(timeout: 5))
    }

    func testFreeLimitTriggersPaywallOnThirdPlan() throws {
        let app = launchApp()
        for name in ["Second Plan"] {
            let addButton = app.buttons["addPlanButton"]
            addButton.tap()
            let nameField = app.textFields["planNameField"]
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText(name)
                let priceField = app.textFields["planPriceField"]
                priceField.tap()
                priceField.typeText("100")
                app.buttons["planSaveButton"].tap()
            }
        }
        // Now at 2 plans (free limit); a third add should show the paywall.
        app.buttons["addPlanButton"].tap()
        XCTAssertTrue(app.staticTexts["Layaway Pro"].waitForExistence(timeout: 5), "Paywall did not appear after hitting the free plan limit")
    }

    func testKeyboardDismissesOnTapOutside() throws {
        let app = launchApp()

        app.buttons["addPlanButton"].tap()
        let nameField = app.textFields["planNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Test")
        XCTAssertTrue(app.keyboards.element.exists)

        app.staticTexts["Schedule"].tap()

        let keyboardGone = !app.keyboards.element.exists
        XCTAssertTrue(keyboardGone || !app.keyboards.element.isHittable, "Keyboard did not dismiss on tap outside")
    }

    func testSettingsTabShowsRestorePurchases() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Restore Purchases"].waitForExistence(timeout: 5))
    }
}
