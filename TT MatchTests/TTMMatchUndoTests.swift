//
//  TTMMatchUndoTests.swift
//  TT MatchTests
//

import Testing
@testable import TT_Match

@Suite("Undo")
@MainActor
struct TTMMatchUndoTests {

    let fixture = MatchFixture()
    var match: TTMMatch { fixture.match }

    @Test func undoRevertsLastPoint() {
        match.start()
        match.reach(green: 3, blue: 1)
        match.score(.blue)

        match.undo()

        #expect(match.greenScore == 3)
        #expect(match.blueScore == 1)
    }

    @Test func undoRevertsPointsOneByOne() {
        match.start()
        match.score(.green, times: 3)

        match.undo()
        match.undo()

        #expect(match.greenScore == 1)
        #expect(match.canUndo())
    }

    @Test func undoRevertsMoveToNextGame() {
        match.start()
        match.score(.green, times: 11)
        match.playerAction(.green)
        #expect(match.gameScores.count == 2)

        match.undo()

        #expect(match.gameScores.count == 1)
        #expect(match.gameFinished)
        #expect(match.greenScore == 11)
    }

    @Test func undoReopensFinishedGame() {
        match.start()
        match.score(.green, times: 11)

        match.undo()

        #expect(!match.gameFinished)
        #expect(match.greenScore == 10)
    }

    @Test("With empty history undo cancels the match start")
    func undoWithoutHistoryClearsFirstServe() {
        match.start(serving: .blue)
        #expect(!match.canUndo())

        match.undo()

        #expect(match.firstServe == nil)
        #expect(match.serve == nil)
    }

    @Test func undoBeforeStartDoesNothing() {
        match.undo()

        #expect(match.firstServe == nil)
        #expect(match.gameScores.count == 1)
        #expect(match.greenScore == 0)
    }
}
