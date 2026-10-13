import XCTest

/// A scripted end-to-end stroll through the app, paced so a screen
/// recording shows each step (roughly 30–60 seconds total).
final class WalkthroughTests: XCTestCase {

    @MainActor
    func testWalkthrough() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetState"]
        app.launch()
        sleep(2)

        // Route tab: load the sample job.
        app.tabBars.buttons["Route"].tap()
        let loadSample = app.buttons["loadSampleJobEmpty"]
        XCTAssertTrue(loadSample.waitForExistence(timeout: 10))
        loadSample.tap()
        XCTAssertTrue(app.staticTexts["jobName"].waitForExistence(timeout: 5))
        sleep(2)

        // Fit Check: read the banner, scroll through the cards.
        app.tabBars.buttons["Fit Check"].tap()
        XCTAssertTrue(app.staticTexts["routeSummary"].waitForExistence(timeout: 5))
        sleep(2)
        app.swipeUp()
        sleep(2)
        app.swipeUp()
        sleep(2)
        app.swipeDown()
        sleep(1)

        // Back to Route, open the piano picker, choose a different piano.
        app.tabBars.buttons["Route"].tap()
        let pianoCard = app.buttons["pianoCard"]
        XCTAssertTrue(pianoCard.waitForExistence(timeout: 5))
        pianoCard.tap()
        let console = app.descendants(matching: .any)
            .element(matching: .any, identifier: "pianoRow.console")
        XCTAssertTrue(console.waitForExistence(timeout: 10))
        sleep(1)
        console.tap()
        XCTAssertTrue(app.buttons["useThisPiano"].waitForExistence(timeout: 5))
        sleep(1)
        app.buttons["useThisPiano"].tap()
        sleep(2)

        // Fit Check again: results should now reflect the Console upright.
        app.tabBars.buttons["Fit Check"].tap()
        XCTAssertTrue(app.staticTexts["routeSummary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["result.Front door"].waitForExistence(timeout: 5))
        sleep(2)
        app.swipeUp()
        sleep(2)
    }
}
