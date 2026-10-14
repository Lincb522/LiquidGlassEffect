import XCTest

final class LiquidGlassDemoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testOpticalControlsAndCaptureModes() {
        launchOptics()
        XCTAssertTrue(app.staticTexts["optics.title"].waitForExistence(timeout: 15))
        assertControl("optics.motion", value: "Off")
        assertControl("optics.dark", value: "Off")
        assertControl("optics.tint", value: "Off")
        assertControl("optics.corners", value: "Off")
        assertControl("optics.group", value: "Off")
        assertControl("optics.glass", value: "On")
        capture("01-light-independent")

        app.buttons["optics.tint"].tap()
        assertControl("optics.tint", value: "On")
        capture("02-light-blue-tint")

        app.buttons["optics.corners"].tap()
        assertControl("optics.corners", value: "On")
        capture("03-tight-corners")

        app.buttons["optics.dark"].tap()
        assertControl("optics.dark", value: "On")
        capture("04-dark-blue-tint")

        app.buttons["optics.group"].tap()
        assertControl("optics.group", value: "On")
        XCTAssertTrue(app.staticTexts["SHARED CAPTURE"].exists)
        capture("05-dark-grouped")

        app.buttons["optics.motion"].tap()
        assertControl("optics.motion", value: "On")
        capture("06-moving-backdrop-a")
        capture("07-moving-backdrop-b")
        app.buttons["optics.motion"].tap()
        assertControl("optics.motion", value: "Off")

        app.buttons["optics.glass"].tap()
        assertControl("optics.glass", value: "Off")
        capture("08-reference-without-glass")
        app.buttons["optics.glass"].tap()
        assertControl("optics.glass", value: "On")
    }

    func testGroupedAndStandaloneReferenceScreenshots() {
        launchOptics()
        XCTAssertTrue(app.staticTexts["optics.title"].waitForExistence(timeout: 15))
        capture("reference-light-standalone")
        app.buttons["optics.group"].tap()
        assertControl("optics.group", value: "On")
        capture("reference-light-grouped")
        app.buttons["optics.group"].tap()
        app.buttons["optics.dark"].tap()
        capture("reference-dark-standalone")
        app.buttons["optics.group"].tap()
        capture("reference-dark-grouped")
    }

    func testGalleryInteractionAndOpticsEntry() {
        app.launch()
        let like = app.buttons["gallery.like"]
        XCTAssertTrue(like.waitForExistence(timeout: 15))
        XCTAssertEqual(like.value as? String, "0")
        like.tap()
        XCTAssertEqual(like.value as? String, "1")
        let bookmark = app.buttons["gallery.bookmark"]
        bookmark.tap()
        XCTAssertEqual(bookmark.value as? String, "On")
        capture("gallery-buttons-interaction")

        app.buttons["gallery.openOptics"].tap()
        XCTAssertTrue(app.staticTexts["optics.title"].waitForExistence(timeout: 10))
        app.buttons["optics.close"].tap()
        XCTAssertTrue(app.staticTexts["gallery.page.buttons"].waitForExistence(timeout: 10))
    }

    private func launchOptics() {
        app.launchArguments = ["--optics"]
        app.launch()
    }

    private func assertControl(_ identifier: String, value: String,
                               file: StaticString = #filePath, line: UInt = #line) {
        let control = app.buttons[identifier]
        XCTAssertTrue(control.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertEqual(control.value as? String, value, file: file, line: line)
    }

    private func capture(_ name: String) {
        // Let the actual Metal drawable / capture path settle before attaching.
        Thread.sleep(forTimeInterval: 0.8)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
