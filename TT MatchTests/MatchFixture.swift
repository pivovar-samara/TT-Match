//
//  MatchFixture.swift
//  TT MatchTests
//

import Foundation
@testable import TT_Match

/// Owns a `TTMMatch` backed by an isolated `UserDefaults` suite, removed when the fixture goes away.
final class MatchFixture {

    let suiteName = "TTMatchTests.\(UUID().uuidString)"
    let userDefaults: UserDefaults
    let match: TTMMatch

    init(gameCount: Int = 7) {
        self.userDefaults = UserDefaults(suiteName: suiteName)!
        self.match = TTMMatch(userDefaults: userDefaults)
        if gameCount != self.match.settings.gameCount {
            var settings = self.match.settings
            settings.gameCount = gameCount
            self.match.settings = settings
        }
    }

    deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    /// A fresh match on the same storage, restored the way the app does on launch.
    func restoredMatch() -> TTMMatch {
        let restored = TTMMatch(userDefaults: userDefaults)
        restored.restore()
        return restored
    }
}

extension TTMMatch {

    /// Starts the match with `server` serving first.
    func start(serving server: TTMMatchPlayer = .green) {
        self.playerAction(server)
    }

    func score(_ player: TTMMatchPlayer, times: Int = 1) {
        for _ in 0..<times {
            self.playerAction(player)
        }
    }

    /// Plays points so the current game reaches `green`:`blue`, alternating to avoid finishing early.
    func reach(green: Int, blue: Int) {
        let common = min(green, blue)
        for _ in 0..<common {
            self.score(.green)
            self.score(.blue)
        }
        self.score(.green, times: green - common)
        self.score(.blue, times: blue - common)
    }

    /// Wins the current game 11:0 for `player` and moves on to the next game.
    func winGame(_ player: TTMMatchPlayer) {
        self.score(player, times: 11)
        if !self.matchFinished {
            self.playerAction(player)
        }
    }

    var greenScore: Int { self.currentPlayerScore(.green) }
    var blueScore: Int { self.currentPlayerScore(.blue) }
}
