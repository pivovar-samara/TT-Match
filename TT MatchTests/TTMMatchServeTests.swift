//
//  TTMMatchServeTests.swift
//  TT MatchTests
//

import Testing
@testable import TT_Match

@Suite("Serve rotation")
@MainActor
struct TTMMatchServeTests {

    let fixture = MatchFixture()
    var match: TTMMatch { fixture.match }

    @Test func noServeBeforeMatchStarts() {
        #expect(match.firstServe == nil)
        #expect(match.serve == nil)
        #expect(!match.isStarted)
    }

    @Test(arguments: [TTMMatchPlayer.green, .blue])
    func firstTapPicksServerWithoutScoring(_ player: TTMMatchPlayer) {
        match.start(serving: player)

        #expect(match.firstServe == player)
        #expect(match.serve == player)
        #expect(match.greenScore == 0)
        #expect(match.blueScore == 0)
    }

    @Test("Serve changes every two points", arguments: 0...9)
    func twoServesEach(totalPoints: Int) {
        match.start(serving: .green)
        match.reach(green: totalPoints - totalPoints / 2, blue: totalPoints / 2)

        let expected: TTMMatchPlayer = totalPoints % 4 < 2 ? .green : .blue
        #expect(match.serve == expected)
    }

    @Test("At 10:10 and beyond serve changes every point")
    func oneServeEachAtDeuce() {
        match.start(serving: .green)
        match.reach(green: 10, blue: 10)
        #expect(match.serve == .green)

        match.score(.green)   // 11:10
        #expect(match.serve == .blue)

        match.score(.blue)    // 11:11
        #expect(match.serve == .green)

        match.score(.blue)    // 11:12
        #expect(match.serve == .blue)
    }

    @Test("Deuce rotation follows pointCount")
    func deuceThresholdUsesPointCount() {
        var settings = match.settings
        settings.pointCount = 5
        match.settings = settings

        match.start(serving: .green)
        match.reach(green: 4, blue: 4)
        #expect(match.serve == .green)

        match.score(.green)   // 5:4
        #expect(match.serve == .blue)
    }

    @Test("The other player serves first in the next game")
    func firstServeAlternatesByGame() {
        match.start(serving: .green)

        match.winGame(.green)
        #expect(match.gameScores.count == 2)
        #expect(match.serve == .blue)

        match.winGame(.green)
        #expect(match.gameScores.count == 3)
        #expect(match.serve == .green)
    }
}
