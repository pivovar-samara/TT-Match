//
//  TTMFoldLayout.swift
//  TT Match
//

import CoreGraphics

/// The match screen layout around a vertical fold (iPhone Duo inner display in landscape):
/// the score buttons are symmetric around the fold, the games column moves to the edge with more room
/// (opposite the camera strip).
///
/// Geometry is in the container's coordinates, from the leading edge.
struct TTMFoldLayout: Equatable {

    enum ColumnEdge: Equatable {
        case leading, trailing
    }

    static let margin: CGFloat = 16.0
    static let spacing: CGFloat = 16.0
    static let minColumnWidth: CGFloat = 48.0
    static let minButtonWidth: CGFloat = 120.0

    let columnEdge: ColumnEdge
    let columnWidth: CGFloat
    let buttonWidth: CGFloat
    /// Between the buttons, centered on the fold: the fold itself, at least the regular spacing.
    let gap: CGFloat
    /// From the container's leading edge to the first view.
    let leadingPadding: CGFloat

    /// Nil when there is no vertical fold across the container or the buttons would get too narrow:
    /// use the regular layout.
    init?(containerWidth: CGFloat, fold: CGRect?) {
        guard let fold, fold.height > fold.width, fold.midX > 0.0, fold.midX < containerWidth else { return nil }

        let gap = max(fold.width, Self.spacing)
        let roomLeading = fold.midX - gap / 2.0 - Self.margin
        let roomTrailing = containerWidth - fold.midX - gap / 2.0 - Self.margin
        let columnEdge: ColumnEdge = roomTrailing >= roomLeading ? .trailing : .leading
        let larger = max(roomLeading, roomTrailing)
        let smaller = min(roomLeading, roomTrailing)

        let buttonWidth = min(smaller, larger - Self.spacing - Self.minColumnWidth)
        guard buttonWidth >= Self.minButtonWidth else { return nil }

        self.columnEdge = columnEdge
        self.columnWidth = larger - Self.spacing - buttonWidth
        self.buttonWidth = buttonWidth
        self.gap = gap
        self.leadingPadding = columnEdge == .trailing ? fold.midX - gap / 2.0 - buttonWidth : Self.margin
    }
}
