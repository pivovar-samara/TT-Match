//
//  TTMMatchGameFlowTests.swift
//  TT MatchTests
//

import Testing
@testable import TT_Match

@Suite("Games and match flow")
@MainActor
struct TTMMatchGameFlowTests {

    let fixture = MatchFixture()
    var match: TTMMatch { fixture.match }

    @Test(arguments: [
        (11, 9, true),
        (11, 10, false),
        (10, 10, false),
        (12, 10, true),
        (9, 11, true),
        (10, 0, false),
    ])
    func gameFinishesAtElevenWithTwoPointLead(green: Int, blue: Int, finished: Bool) {
        match.start()
        match.reach(green: green, blue: blue)

        #expect(match.gameFinished == finished)
        #expect(match.gameWinner == (finished ? (green > blue ? .green : .blue) : nil))
    }

    @Test(arguments: [
        (10, 0, true),
        (0, 10, true),
        (11, 10, true),
        (10, 10, false),
        (9, 9, false),
        (9, 0, false),
    ])
    func gamePoint(green: Int, blue: Int, expected: Bool) {
        match.start()
        match.reach(green: green, blue: blue)

        #expect(match.gamePoint == expected)
    }

    @Test("Finished game counts towards games score")
    func gamesScoreIncludesFinishedGame() {
        match.start()
        match.reach(green: 10, blue: 5)
        #expect(match.gamesScore(.green) == 0)

        match.score(.green)
        #expect(match.gamesScore(.green) == 1)
        #expect(match.gamesScore(.blue) == 0)
    }

    @Test("Tap after a finished game starts the next one without scoring")
    func tapAfterGameStartsNextGame() {
        match.start()
        match.score(.blue, times: 11)
        #expect(match.gameFinished)

        match.playerAction(.green)

        #expect(match.gameScores.count == 2)
        #expect(!match.gameFinished)
        #expect(match.greenScore == 0)
        #expect(match.blueScore == 0)
        #expect(match.gamesScore(.blue) == 1)
    }

    @Test(arguments: [3, 5, 7])
    func matchFinishesAfterMajorityOfGames(gameCount: Int) {
        let fixture = MatchFixture(gameCount: gameCount)
        let match = fixture.match
        match.start()

        let gamesToWin = gameCount / 2 + 1
        for _ in 0..<(gamesToWin - 1) {
            match.winGame(.blue)
        }
        #expect(!match.matchFinished)
        #expect(match.winner == nil)

        match.winGame(.blue)
        #expect(match.matchFinished)
        #expect(match.winner == .blue)
        #expect(match.gamesScore(.blue) == gamesToWin)
    }

    @Test("Players switch sides every game")
    func sidesSwitchEachGame() {
        match.start()
        #expect(match.players == [.green, .blue])

        match.winGame(.green)
        #expect(match.players == [.blue, .green])

        match.winGame(.blue)
        #expect(match.players == [.green, .blue])
    }

    @Test("In the deciding game sides switch when the leader reaches 5")
    func sidesSwitchMidDecidingGame() {
        let fixture = MatchFixture(gameCount: 3)
        let match = fixture.match
        match.start()
        match.winGame(.green)
        match.winGame(.blue)
        #expect(match.isFinalGame())

        match.reach(green: 4, blue: 4)
        #expect(match.players == [.green, .blue])

        match.score(.blue)    // 4:5
        #expect(match.players == [.blue, .green])
    }

    @Test("Sides do not switch mid-game outside the deciding game")
    func noMidGameSwitchInRegularGame() {
        match.start()
        match.reach(green: 8, blue: 2)
        #expect(match.players == [.green, .blue])
    }
}
