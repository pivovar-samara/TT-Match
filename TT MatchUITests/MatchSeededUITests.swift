//
//  MatchSeededUITests.swift
//  TT MatchUITests
//
//  Scenarios that start one point before the interesting moment instead of playing up to it.
//

import XCTest

final class MatchSeededUITests: TTMUITestCase {

    func testGamePointWinsGameThenBackgroundTapStartsNextGame() {
        // One game played → green is on the left.
        launch(match: MatchSeed(games: [[10, 0]]))
        assertScore(left: 10, right: 0)
        assertNoValue(game(0))

        tapAndSettle(leftScore)
        assertValue(game(0), "11-0")

        tapAndSettle(game(0))

        assertScore(left: 0, right: 0)
        // Second game: sides switched, so the finished game now reads blue-green.
        assertValue(game(0), "0-11")
    }

    func testDeuceNeedsTwoPointLead() {
        launch(match: MatchSeed(games: [[10, 10]]))

        tapAndSettle(leftScore)
        assertScore(left: 11, right: 10)
        assertNoValue(game(0))

        tapAndSettle(leftScore)
        assertValue(game(0), "12-10")
    }

    func testMatchPointFinishesMatchThenTapStartsNewMatch() {
        // Best of 3, green leads 1:0 and needs one point. Two games → green is on the right.
        launch(match: MatchSeed(games: [[11, 5], [10, 0]], gameCount: 3))
        assertScore(left: 0, right: 10)

        tapAndSettle(rightScore)
        XCTAssertTrue(settings.waitForNonExistence(timeout: 3))

        tapAndSettle(leftScore)

        assertScore(left: 0, right: 0)
        XCTAssertTrue(settings.waitForExistence(timeout: 3))
        XCTAssertTrue(randomServe.exists)
    }

    func testUndoReopensFinishedGame() {
        launch(match: MatchSeed(games: [[10, 0]]))
        tapAndSettle(leftScore)
        assertValue(game(0), "11-0")

        tapUndo(left: true)

        assertScore(left: 10, right: 0)
        assertNoValue(game(0))
    }
}
