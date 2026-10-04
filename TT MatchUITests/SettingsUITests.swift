//
//  SettingsUITests.swift
//  TT MatchUITests
//

import XCTest

final class SettingsUITests: TTMUITestCase {

    func testChangeGameCountBeforeMatch() {
        launch()
        XCTAssertEqual(settings.label, "7")

        settings.tap()
        let threeGames = app.buttons["3 games, till 2 wins"]
        XCTAssertTrue(threeGames.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["5 games, till 3 wins"].exists)
        XCTAssertTrue(app.buttons["7 games, till 4 wins"].exists)
        threeGames.tap()

        XCTAssertTrue(threeGames.waitForNonExistence(timeout: 3))
        XCTAssertEqual(settings.label, "3")
    }

    func testResetMatchConfirmed() {
        launch(match: MatchSeed(games: [[5, 3]]))

        settings.tap()
        let confirm = app.buttons["Yes"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        confirm.tap()

        assertScore(left: 0, right: 0)
        XCTAssertTrue(randomServe.waitForExistence(timeout: 3))
    }

    func testResetMatchCancelled() {
        launch(match: MatchSeed(games: [[5, 3]]))

        settings.tap()
        let confirm = app.buttons["Yes"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3))
        dismissActionSheet()

        XCTAssertTrue(confirm.waitForNonExistence(timeout: 3))
        assertScore(left: 5, right: 3)
        XCTAssertFalse(randomServe.exists)
    }
}
