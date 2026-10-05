//
//  TTMFoldLayoutTests.swift
//  TT MatchTests
//

import CoreGraphics
import Testing
@testable import TT_Match

@Suite("Fold layout")
struct TTMFoldLayoutTests {

    /// A vertical fold of `width` centered at `x`.
    private func fold(x: CGFloat, width: CGFloat = 0.0) -> CGRect {
        CGRect(x: x - width / 2.0, y: 0.0, width: width, height: 600.0)
    }

    /// Asserts that the views fill `containerWidth` and the buttons meet symmetrically at `foldX`.
    private func expectSymmetric(_ layout: TTMFoldLayout, containerWidth: CGFloat, foldX: CGFloat) {
        let spacing = TTMFoldLayout.spacing
        let column = layout.columnWidth + spacing
        let firstButton = layout.leadingPadding + (layout.columnEdge == .leading ? column : 0.0)
        #expect(firstButton + layout.buttonWidth + layout.gap / 2.0 == foldX)

        let end = firstButton + 2.0 * layout.buttonWidth + layout.gap + (layout.columnEdge == .trailing ? column : 0.0)
        #expect(end <= containerWidth - TTMFoldLayout.margin)
    }

    @Test func columnGoesOppositeTheCameraOnTheLeading() throws {
        // The inner display in landscape: an 84 pt camera strip on the leading side.
        let width: CGFloat = 951.0 - 84.0
        let foldX = 951.0 / 2.0 - 84.0
        let layout = try #require(TTMFoldLayout(containerWidth: width, fold: fold(x: foldX)))

        #expect(layout.columnEdge == .trailing)
        #expect(layout.columnWidth >= TTMFoldLayout.minColumnWidth)
        #expect(layout.leadingPadding == TTMFoldLayout.margin)
        expectSymmetric(layout, containerWidth: width, foldX: foldX)
    }

    @Test func columnGoesOppositeTheCameraOnTheTrailing() throws {
        let width: CGFloat = 951.0 - 84.0
        let foldX = 951.0 / 2.0
        let layout = try #require(TTMFoldLayout(containerWidth: width, fold: fold(x: foldX)))

        #expect(layout.columnEdge == .leading)
        #expect(layout.leadingPadding == TTMFoldLayout.margin)
        expectSymmetric(layout, containerWidth: width, foldX: foldX)
    }

    @Test func centeredFoldKeepsTheMinimumColumn() throws {
        let layout = try #require(TTMFoldLayout(containerWidth: 951.0, fold: fold(x: 475.5)))

        #expect(layout.columnWidth == TTMFoldLayout.minColumnWidth)
        #expect(layout.leadingPadding > TTMFoldLayout.margin)
        expectSymmetric(layout, containerWidth: 951.0, foldX: 475.5)
    }

    @Test func wideFoldWidensTheGap() throws {
        let layout = try #require(TTMFoldLayout(containerWidth: 867.0, fold: fold(x: 391.5, width: 40.0)))

        #expect(layout.gap == 40.0)
        expectSymmetric(layout, containerWidth: 867.0, foldX: 391.5)
    }

    @Test func noVerticalFoldMeansTheRegularLayout() {
        #expect(TTMFoldLayout(containerWidth: 951.0, fold: nil) == nil)
        #expect(TTMFoldLayout(containerWidth: 669.0, fold: CGRect(x: 0.0, y: 475.0, width: 669.0, height: 0.0)) == nil)
    }

    @Test func foldOutsideTheWindowMeansTheRegularLayout() {
        // Split View: the app on one half of the inner display.
        #expect(TTMFoldLayout(containerWidth: 400.0, fold: fold(x: 420.0)) == nil)
    }

    @Test func foldNearTheEdgeMeansTheRegularLayout() {
        #expect(TTMFoldLayout(containerWidth: 951.0, fold: fold(x: 100.0)) == nil)
    }
}
