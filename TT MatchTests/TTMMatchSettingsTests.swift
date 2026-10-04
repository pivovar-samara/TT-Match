//
//  TTMMatchSettingsTests.swift
//  TT MatchTests
//

import Testing
@testable import TT_Match

@Suite("Match settings")
@MainActor
struct TTMMatchSettingsTests {

    @Test func defaults() {
        let settings = TTMMatchSettings(json: nil)

        #expect(settings.pointCount == 11)
        #expect(settings.gameCount == 7)
        #expect(settings.servesCount == 2)
        #expect(settings.minServesCount == 1)
    }

    @Test func jsonRoundTrip() {
        var settings = TTMMatchSettings(json: nil)
        settings.gameCount = 3
        settings.pointCount = 21

        let restored = TTMMatchSettings(json: settings.toJson())

        #expect(restored == settings)
    }

    @Test func partialJsonKeepsDefaults() {
        let settings = TTMMatchSettings(json: ["gameCount": 5])

        #expect(settings.gameCount == 5)
        #expect(settings.pointCount == 11)
    }

    @Test func wrongTypesAreIgnored() {
        let settings = TTMMatchSettings(json: ["gameCount": "5", "pointCount": true])

        #expect(settings.gameCount == 7)
        #expect(settings.pointCount == 11)
    }
}
