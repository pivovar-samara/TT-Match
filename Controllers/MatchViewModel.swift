//
//  MatchViewModel.swift
//  TT Match
//

import Observation

/// What the settings button does in the current state of the match.
enum TTMSettingsMode: Equatable {
    /// Before the first serve: choose the number of games (shows the current count).
    case gameCount(Int)
    /// During the match: offer to reset it.
    case reset
    /// The match is finished: the button is hidden.
    case hidden
}

/// Screen logic for the match: user intents, analytics, tap lockout and the state the UI shows.
/// The UI only calls intents and renders the properties below.
@MainActor
@Observable
final class MatchViewModel {

    let match: TTMMatch

    /// True for `secondsToDeclineTaps` after each point or undo; the UI ignores input meanwhile.
    private(set) var isInputLocked = false

    /// How many points each player has scored with an animation. The UI animates a player's button when it changes.
    private(set) var pointAnimations: [TTMMatchPlayer: Int] = [:]

    @ObservationIgnored private let analytics: TTMAnalyticsTracking
    @ObservationIgnored private var inputLockID = 0

    init(match: TTMMatch = TTMMatch.currentMatch, analytics: TTMAnalyticsTracking = TTMAnalyticsTracker()) {
        self.match = match
        self.analytics = analytics
    }

    // MARK: - State

    var leftPlayer: TTMMatchPlayer { match.players[0] }
    var rightPlayer: TTMMatchPlayer { match.players[1] }

    /// The match winner; the whole screen takes their color.
    var matchWinner: TTMMatchPlayer? { match.winner }

    /// The winner of a just finished game (not the last one); the score area takes their color.
    var gameWinner: TTMMatchPlayer? {
        match.matchFinished ? nil : match.gameWinner
    }

    /// The serve is not decided yet: offer to pick it at random.
    var showsServeRandomizer: Bool { match.serve == nil }

    /// Finished games are shown once the match has started.
    var showsGames: Bool { match.serve != nil }

    var settingsMode: TTMSettingsMode {
        if match.matchFinished {
            return .hidden
        }
        if match.serve == nil {
            return .gameCount(match.settings.gameCount)
        }
        return .reset
    }

    /// Keep the screen on until the match is finished.
    var isIdleTimerDisabled: Bool { !match.matchFinished }

    // MARK: - Intents

    /// A tap on a player's score. Returns true when the point should be animated on that player's button.
    @discardableResult
    func tap(_ player: TTMMatchPlayer) -> Bool {
        let hasServe = match.serve != nil
        let gameFinished = match.gameFinished
        let matchFinished = match.matchFinished

        if matchFinished {
            TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.newGame)
            match.reset()
        } else {
            if !hasServe {
                analytics.matchStarted(gameCount: match.settings.gameCount)
            }
            match.playerAction(player)
        }

        let gameFinishedAfter = match.gameFinished
        let matchFinishedAfter = match.matchFinished

        if !matchFinished && matchFinishedAfter {
            analytics.matchCompleted(gamesPlayed: match.gameScores.count)
        } else if !gameFinished && gameFinishedAfter {
            analytics.gameCompleted(gameNumber: match.gameScores.count)
        }

        lockInput()
        let animated = hasServe && !gameFinished && !matchFinished && !gameFinishedAfter && !matchFinishedAfter
        if animated {
            pointAnimations[player, default: 0] += 1
        }
        return animated
    }

    /// A press of a hardware volume button. Ignored while input is locked.
    /// Returns true when the point should be animated, as `tap(_:)`.
    @discardableResult
    func hardwareTap(_ player: TTMMatchPlayer) -> Bool {
        guard !isInputLocked else { return false }
        return tap(player)
    }

    /// A tap outside the score buttons starts the next game (or match) once one is finished.
    func backgroundTap() {
        guard match.gameFinished || match.matchFinished else { return }
        tap(match.players[0])
    }

    func undo() {
        if match.firstServe != nil {
            analytics.undoUsed()
        }
        match.undo()
        lockInput()
    }

    /// Whether the serve can still be picked at random.
    var canRandomizeServe: Bool { match.firstServe == nil }

    /// Call when the randomization animation starts.
    func beginServeRandomization() {
        TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tap)
    }

    /// Call when the randomization animation ends: picks the first server and starts the match.
    @discardableResult
    func completeServeRandomization() -> TTMMatchPlayer {
        TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tapServiceChanged)
        let player = TTMMatchPlayer.rand()
        match.firstServe = player
        analytics.matchStarted(gameCount: match.settings.gameCount)
        return player
    }

    func setGameCount(_ gameCount: Int) {
        var settings = match.settings
        settings.gameCount = gameCount
        match.settings = settings
        analytics.settingsChanged(gameCount: gameCount)
    }

    func resetMatch() {
        analytics.matchReset()
        match.reset()
    }

    // MARK: - Private

    private func lockInput() {
        isInputLocked = true
        inputLockID += 1
        let lockID = inputLockID
        delay(secondsToDeclineTaps) { [weak self] in
            guard let self, self.inputLockID == lockID else { return }
            self.isInputLocked = false
        }
    }
}
