//
//  TTMUITestCase.swift
//  TT MatchUITests
//

import XCTest

/// A match to start the app with, in the format `TTMMatch.save()` writes.
/// Scores are `[green, blue]` per game. The left player is green when the number of games is odd
/// and blue when it is even (sides switch every game). Exception: in the deciding game
/// (`games.count == gameCount`) sides switch again once the leader reaches `pointCount / 2`,
/// so there green is on the right (see `TTMMatch.players`).
struct MatchSeed {
    var games: [[Int]]
    var firstServe: Int = 1     // 1 = green, 2 = blue (TTMMatchPlayer raw values)
    var gameCount: Int = 7
    var pointCount: Int = 11

    var json: String {
        let dict: [String: Any] = [
            "games": games,
            "firstServe": String(firstServe),
            "settings": ["gameCount": gameCount, "pointCount": pointCount],
            "history": [] as [Any],
        ]
        let data = try! JSONSerialization.data(withJSONObject: dict)
        return String(data: data, encoding: .utf8)!
    }
}

class TTMUITestCase: XCTestCase {

    var app: XCUIApplication!

    /// The app ignores taps for `secondsToDeclineTaps` (1 s) after every point or undo.
    let tapLockout: TimeInterval = 1.1

    var leftScore: XCUIElement { app.buttons["score.left"] }
    var rightScore: XCUIElement { app.buttons["score.right"] }
    var settings: XCUIElement { app.buttons["settings"] }
    var randomServe: XCUIElement { app.buttons["randomServe"] }

    func game(_ index: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "game.\(index)").firstMatch
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func launch(match seed: MatchSeed? = nil) {
        app = XCUIApplication()
        app.launchArguments = ["-UITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if let seed {
            app.launchEnvironment["TTM_UITEST_MATCH"] = seed.json
        }
        app.launch()
        XCTAssertTrue(leftScore.waitForExistence(timeout: 5))
    }

    func tapUndo(left: Bool) {
        tapAndSettle(app.buttons[left ? "undo.left" : "undo.right"])
    }

    /// Dismisses the action sheet. On iPhone it may be shown as a popover without a Cancel button.
    func dismissActionSheet() {
        let cancel = app.buttons["Cancel"]
        if cancel.exists {
            cancel.tap()
        } else {
            app.otherElements["PopoverDismissRegion"].tap()
        }
    }

    /// Taps and waits out the app's tap lockout, so the next tap is not ignored.
    func tapAndSettle(_ element: XCUIElement) {
        element.tap()
        Thread.sleep(forTimeInterval: tapLockout)
    }

    func assertValue(_ element: XCUIElement, _ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "value == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 3)
        XCTAssertEqual(result, .completed, "\(element) value is \(String(describing: element.value)), expected \(expected)", file: file, line: line)
    }

    func assertNoValue(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(((element.value as? String) ?? "").isEmpty, "\(element) has value \(String(describing: element.value))", file: file, line: line)
    }

    func assertScore(left: Int, right: Int, file: StaticString = #filePath, line: UInt = #line) {
        assertValue(leftScore, String(left), file: file, line: line)
        assertValue(rightScore, String(right), file: file, line: line)
    }
}
