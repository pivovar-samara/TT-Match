//
//  TTMAnalytics.swift
//  TT Match
//

import FirebaseAnalytics

enum TTMAnalytics {

    // MARK: - Match lifecycle

    /// Fired when a new match starts and the first server is chosen
    /// (either via serve randomization or on the first direct score tap).
    static func matchStarted(gameCount: Int) {
        Analytics.logEvent("match_started", parameters: ["game_count": gameCount])
    }

    /// Fired when the user explicitly resets the current match mid-game.
    static func matchReset() {
        Analytics.logEvent("match_reset", parameters: nil)
    }

    /// Fired when a single game within the match ends.
    /// - Parameter gameNumber: 1-indexed number of the completed game.
    static func gameCompleted(gameNumber: Int) {
        Analytics.logEvent("game_completed", parameters: ["game_number": gameNumber])
    }

    /// Fired when the overall match ends (a player wins enough games).
    /// - Parameter gamesPlayed: Total number of games played in the match.
    static func matchCompleted(gamesPlayed: Int) {
        Analytics.logEvent("match_completed", parameters: ["games_played": gamesPlayed])
    }

    // MARK: - User actions

    /// Fired each time the undo action is triggered.
    static func undoUsed() {
        Analytics.logEvent("undo_used", parameters: nil)
    }

    /// Fired when the user changes the match format (number of games).
    static func settingsChanged(gameCount: Int) {
        Analytics.logEvent("settings_changed", parameters: ["game_count": gameCount])
    }
}

/// The analytics events `MatchViewModel` reports. Lets unit tests record events instead of sending them.
protocol TTMAnalyticsTracking {
    func matchStarted(gameCount: Int)
    func matchReset()
    func gameCompleted(gameNumber: Int)
    func matchCompleted(gamesPlayed: Int)
    func undoUsed()
    func settingsChanged(gameCount: Int)
}

/// Forwards events to `TTMAnalytics`.
struct TTMAnalyticsTracker: TTMAnalyticsTracking {
    func matchStarted(gameCount: Int) { TTMAnalytics.matchStarted(gameCount: gameCount) }
    func matchReset() { TTMAnalytics.matchReset() }
    func gameCompleted(gameNumber: Int) { TTMAnalytics.gameCompleted(gameNumber: gameNumber) }
    func matchCompleted(gamesPlayed: Int) { TTMAnalytics.matchCompleted(gamesPlayed: gamesPlayed) }
    func undoUsed() { TTMAnalytics.undoUsed() }
    func settingsChanged(gameCount: Int) { TTMAnalytics.settingsChanged(gameCount: gameCount) }
}
