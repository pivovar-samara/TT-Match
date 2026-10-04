//
//  TTMMatchPersistenceTests.swift
//  TT MatchTests
//

import Foundation
import Testing
@testable import TT_Match

@Suite("Persistence")
@MainActor
struct TTMMatchPersistenceTests {

    let fixture = MatchFixture(gameCount: 5)
    var match: TTMMatch { fixture.match }

    @Test("Saved match is restored on next launch")
    func roundTrip() {
        match.start(serving: .blue)
        match.winGame(.green)
        match.reach(green: 4, blue: 6)

        let restored = fixture.restoredMatch()

        #expect(restored.settings == match.settings)
        #expect(restored.settings.gameCount == 5)
        #expect(restored.firstServe == .blue)
        #expect(restored.serve == match.serve)
        #expect(restored.gameScores == match.gameScores)
        #expect(restored.greenScore == 4)
        #expect(restored.blueScore == 6)
        #expect(restored.gamesScore(.green) == 1)
    }

    @Test("Undo history survives a restart")
    func historyRoundTrip() {
        match.start()
        match.score(.green, times: 2)

        let restored = fixture.restoredMatch()
        restored.undo()

        #expect(restored.greenScore == 1)
    }

    @Test("Stored format matches what the app has always written")
    func storedFormat() throws {
        match.start(serving: .blue)
        match.score(.green)

        let dict = try #require(fixture.userDefaults.object(forKey: "TTMMatch") as? [String: Any])
        #expect(dict["games"] as? [[Int]] == [[1, 0]])
        #expect(dict["firstServe"] as? String == "2")
        #expect(dict["history"] as? [[[Int]]] == [[[0, 0]]])
        let settings = try #require(dict["settings"] as? [String: Any])
        #expect(settings["gameCount"] as? Int == 5)
        #expect(settings["pointCount"] as? Int == 11)
    }

    @Test("A finished match is reset on restore")
    func finishedMatchIsResetOnRestore() {
        let fixture = MatchFixture(gameCount: 3)
        let match = fixture.match
        match.start()
        match.winGame(.green)
        match.winGame(.green)
        #expect(match.matchFinished)

        let restored = fixture.restoredMatch()

        #expect(!restored.matchFinished)
        #expect(restored.firstServe == nil)
        #expect(restored.gameScores.count == 1)
        #expect(restored.settings.gameCount == 3)
    }

    @Test("Changing settings of a finished match resets it")
    func settingsChangeResetsFinishedMatch() {
        let fixture = MatchFixture(gameCount: 3)
        let match = fixture.match
        match.start()
        match.winGame(.green)
        match.winGame(.green)

        let settings = match.settings
        match.settings = settings

        #expect(!match.matchFinished)
        #expect(match.firstServe == nil)
        #expect(!match.canUndo())
    }

    @Test("Empty storage gives a fresh match")
    func restoreFromEmptyStorage() {
        let restored = fixture.restoredMatch()
        #expect(restored.firstServe == nil)
        #expect(restored.gameScores.count == 1)
    }
}
