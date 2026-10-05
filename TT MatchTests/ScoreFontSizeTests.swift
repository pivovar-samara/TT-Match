//
//  ScoreFontSizeTests.swift
//  TT MatchTests
//

import CoreGraphics
import Testing
@testable import TT_Match

@Suite("Score font size")
@MainActor
struct ScoreFontSizeTests {

    @Test func growsWithTheButton() {
        let small = ScoreButton.scoreFontSize(for: CGSize(width: 300.0, height: 300.0))
        let large = ScoreButton.scoreFontSize(for: CGSize(width: 600.0, height: 600.0))

        #expect(large > small)
    }

    @Test func narrowButtonIsLimitedByWidth() {
        let narrow = ScoreButton.scoreFontSize(for: CGSize(width: 200.0, height: 900.0))
        let wider = ScoreButton.scoreFontSize(for: CGSize(width: 300.0, height: 900.0))

        #expect(wider > narrow)
    }

    @Test func wideButtonIsLimitedByHeight() {
        let low = ScoreButton.scoreFontSize(for: CGSize(width: 900.0, height: 300.0))
        let higher = ScoreButton.scoreFontSize(for: CGSize(width: 900.0, height: 400.0))

        #expect(higher > low)
        #expect(low < 300.0)
    }

    @Test func tinyButtonStillHasAFont() {
        #expect(ScoreButton.scoreFontSize(for: .zero) == 1.0)
    }
}
