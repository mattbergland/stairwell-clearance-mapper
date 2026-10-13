import XCTest

final class ScreenshotTests: XCTestCase {

    private func launch(extraArgs: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetState"] + extraArgs
        app.launch()
        return app
    }

    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).element(matching: .any, identifier: id)
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tapTab(_ app: XCUIApplication, _ name: String) {
        _ = app.tabBars.buttons[name].waitForExistence(timeout: 5)
        app.tabBars.buttons[name].tap()
    }

    @MainActor
    func testCaptureScreens() {
        let app = launch()

        // 01 - library
        tapTab(app, "Pianos")
        shot("01-library")

        // Model M sits far enough down the list to be lazy — scroll to it.
        let modelM = el(app, "pianoRow.steinway-model-m")
        var scrolls = 0
        while !modelM.exists && scrolls < 8 {
            app.swipeUp()
            scrolls += 1
            sleep(1)
        }
        XCTAssertTrue(modelM.waitForExistence(timeout: 10))

        // 02 - piano detail
        modelM.tap()
        XCTAssertTrue(app.buttons["useThisPiano"].waitForExistence(timeout: 5))
        shot("02-piano-detail")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // 03 - empty route
        tapTab(app, "Route")
        sleep(1)
        shot("03-route-empty")

        // 04 - route with the sample job loaded
        _ = app.buttons["loadSampleJobEmpty"].waitForExistence(timeout: 5)
        app.buttons["loadSampleJobEmpty"].tap()
        XCTAssertTrue(app.staticTexts["jobName"].waitForExistence(timeout: 5))
        shot("04-route-sample")

        // 05 - obstacle form showing a validation error
        app.buttons["addObstacle"].tap()
        _ = app.buttons["kind.doorway"].waitForExistence(timeout: 5)
        app.buttons["kind.doorway"].tap()
        let widthInches = app.textFields["field.width.inches"]
        XCTAssertTrue(widthInches.waitForExistence(timeout: 5))
        widthInches.tap()
        widthInches.typeText("2")
        XCTAssertTrue(app.staticTexts["fieldError"].waitForExistence(timeout: 5))
        // Dismiss the keyboard so the error line is fully visible.
        _ = app.buttons["Done"].waitForExistence(timeout: 5)
        app.buttons["Done"].tap()
        shot("05-obstacle-form-error")
        // The form is a pushed screen inside the picker sheet — go back,
        // then cancel the sheet so the tab bar is usable again.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        _ = app.buttons["Cancel"].waitForExistence(timeout: 5)
        app.buttons["Cancel"].tap()

        // 06 - results
        tapTab(app, "Fit Check")
        XCTAssertTrue(app.staticTexts["routeSummary"].waitForExistence(timeout: 5))
        shot("06-results")

        // 07 - settings
        tapTab(app, "Settings")
        sleep(1)
        shot("07-settings")
    }

    @MainActor
    func testCaptureAccessibilityXL() {
        let app = launch(extraArgs: ["-UIPreferredContentSizeCategoryName",
                                     "UICTContentSizeCategoryAccessibilityXL"])
        tapTab(app, "Route")
        _ = app.buttons["loadSampleJobEmpty"].waitForExistence(timeout: 10)
        app.buttons["loadSampleJobEmpty"].tap()
        tapTab(app, "Fit Check")
        XCTAssertTrue(app.staticTexts["routeSummary"].waitForExistence(timeout: 10))
        shot("08-results-accessibility-xl")
    }
}
