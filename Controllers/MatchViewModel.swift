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

    /// True for `secondsToDeclineTaps` after each point or undo.
    private(set) var isInputLocked = false

    /// True from the start to the end of the serve randomization animation.
    private(set) var isRandomizingServe = false

    /// False while input is locked or the serve is being randomized; the UI ignores touches meanwhile.
    var acceptsInput: Bool { !isInputLocked && !isRandomizingServe }

    /// How many animated points were scored on the left and on the right button. The UI animates a button
    /// when its counter changes. Counted per side, not per player: players switch sides between games and
    /// in the deciding game, and the animation belongs to the side where the scorer is after the point.
    private(set) var leftPointAnimations = 0
    private(set) var rightPointAnimations = 0

    @ObservationIgnored private let analytics: TTMAnalyticsTracking
    /// Runs a closure after a number of seconds. Tests replace it to control when the input lock ends.
    @ObservationIgnored private let schedule: (Double, @escaping () -> Void) -> Void
    @ObservationIgnored private var inputLockID = 0

    init(match: TTMMatch = TTMMatch.currentMatch,
         analytics: TTMAnalyticsTracking = TTMAnalyticsTracker(),
         schedule: @escaping (Double, @escaping () -> Void) -> Void = { delay($0, closure: $1) }) {
        self.match = match
        self.analytics = analytics
        self.schedule = schedule
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

    /// The serve is not decided yet (or is being randomized): show the randomizer.
    var showsServeRandomizer: Bool { match.serve == nil || isRandomizingServe }

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

    /// A tap on a player's score (touch, accessibility action or hardware volume button).
    /// Ignored while input is locked or the serve is being randomized.
    /// Returns true when the point should be animated on that player's button.
    @discardableResult
    func tap(_ player: TTMMatchPlayer) -> Bool {
        guard acceptsInput else { return false }

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
            if match.players[0] == player {
                leftPointAnimations += 1
            } else {
                rightPointAnimations += 1
            }
        }
        return animated
    }

    /// A tap outside the score buttons starts the next game (or match) once one is finished.
    func backgroundTap() {
        guard match.gameFinished || match.matchFinished else { return }
        tap(match.players[0])
    }

    /// Ignored while input is locked or the serve is being randomized.
    func undo() {
        guard acceptsInput else { return }
        if match.firstServe != nil {
            analytics.undoUsed()
        }
        match.undo()
        lockInput()
    }

    /// Whether the serve can still be picked at random.
    var canRandomizeServe: Bool { match.firstServe == nil }

    /// Call when the randomization animation should start. Returns false when it must not:
    /// the serve is already decided, a randomization is running, or input is locked.
    /// Until `finishServeRandomization()` taps and undo are ignored.
    @discardableResult
    func beginServeRandomization() -> Bool {
        guard canRandomizeServe, acceptsInput else { return false }
        isRandomizingServe = true
        TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tap)
        return true
    }

    /// Call during the animation: picks the first server and starts the match.
    /// Does nothing (returns nil) unless a randomization is running and the serve is still undecided.
    @discardableResult
    func completeServeRandomization() -> TTMMatchPlayer? {
        guard isRandomizingServe, match.firstServe == nil else { return nil }
        TTMSoundManager.sharedManager.playSystemSound(type: TTMSoundType.tapServiceChanged)
        let player = TTMMatchPlayer.rand()
        match.firstServe = player
        analytics.matchStarted(gameCount: match.settings.gameCount)
        return player
    }

    /// Call when the randomization animation is over: input is accepted again.
    func finishServeRandomization() {
        isRandomizingServe = false
    }

    /// Ignored while input is locked or the serve is being randomized.
    func setGameCount(_ gameCount: Int) {
        guard acceptsInput else { return }
        var settings = match.settings
        settings.gameCount = gameCount
        match.settings = settings
        analytics.settingsChanged(gameCount: gameCount)
    }

    /// Ignored while input is locked or the serve is being randomized.
    func resetMatch() {
        guard acceptsInput else { return }
        analytics.matchReset()
        match.reset()
    }

    // MARK: - Private

    private func lockInput() {
        isInputLocked = true
        inputLockID += 1
        let lockID = inputLockID
        schedule(secondsToDeclineTaps) { [weak self] in
            guard let self, self.inputLockID == lockID else { return }
            self.isInputLocked = false
        }
    }
}
