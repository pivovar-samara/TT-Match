//
//  MatchFlowUITests.swift
//  TT MatchUITests
//

import XCTest

final class MatchFlowUITests: TTMUITestCase {

    func testColdStart() {
        launch()

        assertScore(left: 0, right: 0)
        XCTAssertTrue(randomServe.exists)
        assertValue(settings, "7")
    }

    func testFirstTapStartsMatchThenScores() {
        launch()

        tapAndSettle(leftScore)
        XCTAssertTrue(randomServe.waitForNonExistence(timeout: 3))
        assertScore(left: 0, right: 0)

        tapAndSettle(leftScore)
        assertScore(left: 1, right: 0)

        tapAndSettle(rightScore)
        assertScore(left: 1, right: 1)
    }

    func testUndoWithoutHistoryCancelsMatchStart() {
        launch()
        tapAndSettle(leftScore)
        XCTAssertTrue(randomServe.waitForNonExistence(timeout: 3))

        tapUndo(left: true)

        XCTAssertTrue(randomServe.waitForExistence(timeout: 3))
    }

    func testUndoButtonRevertsPoint() {
        launch(match: MatchSeed(games: [[3, 2]]))
        tapAndSettle(leftScore)
        assertScore(left: 4, right: 2)

        tapUndo(left: true)

        assertScore(left: 3, right: 2)
    }

    func testLongPressRevertsPoint() {
        launch(match: MatchSeed(games: [[3, 2]]))
        tapAndSettle(rightScore)
        assertScore(left: 3, right: 3)

        rightScore.press(forDuration: 1.0)
        Thread.sleep(forTimeInterval: tapLockout)

        assertScore(left: 3, right: 2)
    }

    func testRandomServeStartsMatch() {
        launch()

        randomServe.tap()

        XCTAssertTrue(randomServe.waitForNonExistence(timeout: 5))
        Thread.sleep(forTimeInterval: tapLockout)
        tapAndSettle(leftScore)
        assertScore(left: 1, right: 0)
    }
}
