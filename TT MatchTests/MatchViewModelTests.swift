//
//  MatchViewModelTests.swift
//  TT MatchTests
//

import Testing
@testable import TT_Match

/// Holds scheduled closures until the test runs them, so the input lock ends when the test decides.
final class ManualScheduler {
    private(set) var pending: [() -> Void] = []

    func schedule(_ delay: Double, _ closure: @escaping () -> Void) {
        pending.append(closure)
    }

    /// Runs everything scheduled so far: the input lock ends.
    func runAll() {
        let closures = pending
        pending = []
        closures.forEach { $0() }
    }
}

/// Records analytics events instead of sending them.
final class AnalyticsSpy: TTMAnalyticsTracking {
    private(set) var events: [String] = []

    func matchStarted(gameCount: Int) { events.append("match_started:\(gameCount)") }
    func matchReset() { events.append("match_reset") }
    func gameCompleted(gameNumber: Int) { events.append("game_completed:\(gameNumber)") }
    func matchCompleted(gamesPlayed: Int) { events.append("match_completed:\(gamesPlayed)") }
    func undoUsed() { events.append("undo_used") }
    func settingsChanged(gameCount: Int) { events.append("settings_changed:\(gameCount)") }
}

@Suite("Match view model")
@MainActor
struct MatchViewModelTests {

    let fixture: MatchFixture
    let analytics = AnalyticsSpy()
    let scheduler = ManualScheduler()
    let viewModel: MatchViewModel
    var match: TTMMatch { fixture.match }

    init() {
        fixture = MatchFixture(gameCount: 3)
        viewModel = MatchViewModel(match: fixture.match, analytics: analytics, schedule: scheduler.schedule)
    }

    @Test func coldStartOffersServeRandomizerAndGameCount() {
        #expect(viewModel.showsServeRandomizer)
        #expect(!viewModel.showsGames)
        #expect(viewModel.settingsMode == .gameCount(3))
        #expect(viewModel.matchWinner == nil)
        #expect(viewModel.gameWinner == nil)
        #expect(viewModel.isIdleTimerDisabled)
    }

    @Test func firstTapStartsMatchWithoutAnimation() {
        let animated = viewModel.tap(.green)

        #expect(!animated)
        #expect(viewModel.leftPointAnimations == 0)
        #expect(viewModel.rightPointAnimations == 0)
        #expect(match.firstServe == .green)
        #expect(!viewModel.showsServeRandomizer)
        #expect(viewModel.showsGames)
        #expect(viewModel.settingsMode == .reset)
        #expect(analytics.events == ["match_started:3"])
    }

    @Test func pointIsAnimatedOnScorerSide() {
        viewModel.tap(.green)
        scheduler.runAll()

        // First game: green is on the left.
        #expect(viewModel.tap(.blue))
        #expect(match.blueScore == 1)
        #expect(viewModel.leftPointAnimations == 0)
        #expect(viewModel.rightPointAnimations == 1)
    }

    @Test func sideSwitchBetweenGamesDoesNotAnimate() {
        match.start()
        match.score(.green, times: 10)
        viewModel.tap(.green)
        scheduler.runAll()

        // Starts game 2: players switch sides, but nobody scored an animated point.
        viewModel.backgroundTap()

        #expect(viewModel.leftPlayer == .blue)
        #expect(viewModel.leftPointAnimations == 0)
        #expect(viewModel.rightPointAnimations == 0)
    }

    @Test func pointThatSwitchesSidesInDecidingGameAnimatesScorerNewSide() {
        match.start()
        match.winGame(.green)
        match.winGame(.blue)
        match.score(.green, times: 4)
        #expect(viewModel.leftPlayer == .green)

        // Green reaches 5 in the deciding game: sides switch, green is now on the right.
        #expect(viewModel.tap(.green))

        #expect(viewModel.rightPlayer == .green)
        #expect(viewModel.leftPointAnimations == 0)
        #expect(viewModel.rightPointAnimations == 1)
    }

    @Test func tapAndUndoAreIgnoredWhileInputIsLocked() {
        viewModel.tap(.green)
        #expect(viewModel.isInputLocked)

        #expect(!viewModel.tap(.blue))
        viewModel.undo()

        #expect(match.blueScore == 0)
        #expect(match.firstServe == .green)
        #expect(analytics.events == ["match_started:3"])

        scheduler.runAll()
        #expect(!viewModel.isInputLocked)
        #expect(viewModel.tap(.blue))
    }

    @Test func staleTimerDoesNotEndLaterLock() {
        viewModel.tap(.green)
        let firstTimer = scheduler.pending[0]
        scheduler.runAll()

        viewModel.undo()
        firstTimer()
        #expect(viewModel.isInputLocked)

        scheduler.runAll()
        #expect(!viewModel.isInputLocked)
    }

    @Test func gamePointFinishesGameWithoutAnimation() {
        match.start()
        match.score(.green, times: 10)

        #expect(!viewModel.tap(.green))
        #expect(viewModel.gameWinner == .green)
        #expect(viewModel.matchWinner == nil)
        #expect(viewModel.settingsMode == .reset)
        #expect(analytics.events == ["game_completed:1"])
    }

    @Test func backgroundTapIsIgnoredDuringGame() {
        match.start()
        match.score(.green)

        viewModel.backgroundTap()

        #expect(match.greenScore == 1)
        #expect(match.blueScore == 0)
        #expect(!viewModel.isInputLocked)
    }

    @Test func backgroundTapStartsNextGame() {
        match.start()
        match.score(.green, times: 11)

        viewModel.backgroundTap()

        #expect(match.gameScores.count == 2)
        #expect(viewModel.gameWinner == nil)
    }

    @Test func matchPointFinishesMatch() {
        match.start()
        match.winGame(.blue)
        match.score(.blue, times: 10)

        viewModel.tap(.blue)

        #expect(viewModel.matchWinner == .blue)
        #expect(viewModel.gameWinner == nil)
        #expect(viewModel.settingsMode == .hidden)
        #expect(!viewModel.isIdleTimerDisabled)
        #expect(analytics.events == ["match_completed:2"])
    }

    @Test func tapOnFinishedMatchStartsNewOne() {
        match.start()
        match.winGame(.blue)
        match.score(.blue, times: 11)

        viewModel.tap(.green)

        #expect(match.firstServe == nil)
        #expect(viewModel.matchWinner == nil)
        #expect(viewModel.showsServeRandomizer)
        #expect(analytics.events.isEmpty)
    }

    @Test func undoWithoutHistoryCancelsMatchStart() {
        viewModel.tap(.green)
        scheduler.runAll()

        viewModel.undo()

        #expect(match.firstServe == nil)
        #expect(viewModel.showsServeRandomizer)
        #expect(viewModel.isInputLocked)
        #expect(analytics.events == ["match_started:3", "undo_used"])
    }

    @Test func undoBeforeMatchStartIsNotReported() {
        viewModel.undo()

        #expect(analytics.events.isEmpty)
    }

    @Test func serveRandomizationStartsMatch() {
        #expect(viewModel.canRandomizeServe)

        viewModel.beginServeRandomization()
        let player = viewModel.completeServeRandomization()

        #expect(match.firstServe == player)
        #expect(!viewModel.canRandomizeServe)
        #expect(analytics.events == ["match_started:3"])
    }

    @Test func setGameCountUpdatesSettings() {
        viewModel.setGameCount(5)

        #expect(match.settings.gameCount == 5)
        #expect(viewModel.settingsMode == .gameCount(5))
        #expect(analytics.events == ["settings_changed:5"])
    }

    @Test func resetMatchClearsScore() {
        match.start()
        match.score(.green, times: 3)

        viewModel.resetMatch()

        #expect(match.firstServe == nil)
        #expect(match.greenScore == 0)
        #expect(analytics.events == ["match_reset"])
    }
}
