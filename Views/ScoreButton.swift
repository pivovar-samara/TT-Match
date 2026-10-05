//
//  ScoreButton.swift
//  TT Match
//

import SwiftUI

/// A player's half of the score area: current score, games won and the undo button.
/// Tap scores a point, long press undoes the last action.
struct ScoreButton: View {

    enum Side {
        case left, right
    }

    let match: TTMMatch
    let player: TTMMatchPlayer
    let side: Side
    /// Changes when this player scores a point that should be animated.
    let pointAnimationTrigger: Int
    let onTap: () -> Void
    let onUndo: () -> Void
    /// False for a display-only copy (the stand mode scoreboard): no gestures, no undo, hidden from accessibility.
    var isInteractive = true

    @State private var isPressed = false

    private let cornerRadius: CGFloat = 36.0

    var body: some View {
        ZStack(alignment: side == .left ? .bottomLeading : .bottomTrailing) {
            if isInteractive {
                scoreArea
            } else {
                scoreFace
                    .accessibilityHidden(true)
            }
            if isInteractive && hasServe {
                undoButton
                    .padding(16)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Score area

    private var scoreArea: some View {
        scoreFace
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onTapGesture(perform: onTap)
            .onLongPressGesture(minimumDuration: 0.5, perform: onUndo, onPressingChanged: { isPressed = $0 })
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(L(player == .green ? "Accessibility_Player_Green" : "Accessibility_Player_Blue"))
            .accessibilityValue(String(score))
            .accessibilityIdentifier(side == .left ? "score.left" : "score.right")
            .accessibilityAction { onTap() }
    }

    /// The score, games score and serve state, without interaction.
    private var scoreFace: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        return GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Text(String(score))
                    .font(.ttmBold(Self.scoreFontSize(for: proxy.size)))
                    .monospacedDigit()
                    .lineLimit(1)
                    .contentTransition(.numericText(value: Double(score)))
                    .foregroundStyle(scoreColor)
                    .opacity(hasServe ? 1.0 : 0.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(String(match.gamesScore(player)))
                    .font(.ttmHeavy(36.0))
                    .foregroundStyle(scoreColor)
                    .frame(height: 48.0)
                    .padding(.bottom, 14.0)
                    .opacity(hasServe ? 1.0 : 0.0)
            }
            .background(shape.fill(fillColor))
            .overlay(shape.strokeBorder(player.swiftUIColor, lineWidth: isFinished ? 0.0 : 4.0))
        }
        .animation(.snappy, value: score)
        .keyframeAnimator(initialValue: 1.0, trigger: pointAnimationTrigger) { content, scale in
            content.scaleEffect(scale)
        } keyframes: { _ in
            CubicKeyframe(0.85, duration: secondsToDeclineTaps / 2.0)
            SpringKeyframe(1.0, duration: secondsToDeclineTaps / 2.0)
        }
    }

    // MARK: - Undo

    private var undoButton: some View {
        let isPlain = isPressed || isFilled
        return Button(action: onUndo) {
            Image(side == .left ? "undo_left" : "undo_right")
                .renderingMode(.template)
                .foregroundStyle(isPlain ? Color.white.opacity(0.5) : Color.ttmGray)
                .frame(width: 48.0, height: 48.0)
                .ttmCircleBackground(isPlain ? Color.clear : Color.ttmGray.opacity(0.2))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L("Accessibility_Undo"))
        .accessibilityIdentifier(side == .left ? "undo.left" : "undo.right")
    }

    // MARK: - State

    private var score: Int { match.currentPlayerScore(player) }
    private var hasServe: Bool { match.serve != nil }
    private var isServing: Bool { match.serve == player }
    private var isFinished: Bool { match.gameFinished || match.matchFinished }
    /// The button is filled with the player's color (or sits on a colored background): content is white.
    private var isFilled: Bool { isServing || isFinished }

    private var fillColor: Color {
        if isPressed {
            return player.swiftUIColor
        }
        return isServing && !isFinished ? player.swiftUIColor : .clear
    }

    private var scoreColor: Color {
        if isPressed {
            return Color(uiColor: player.color().opaqueColor(0.5))
        }
        return isFilled ? .white : player.swiftUIColor
    }

    /// Room for the games score at the bottom of the button (label height and padding).
    private static let gamesScoreHeight: CGFloat = 48.0 + 14.0

    /// The largest font for a score button of `size`: "00" fits the width (with 16 pt margins), and the
    /// centered line leaves room for the games score below it.
    static func scoreFontSize(for size: CGSize) -> CGFloat {
        let referenceSize: CGFloat = 100.0
        let referenceFont = UIFont.ttmFontBoldOfSize(referenceSize)
        let referenceWidth = ("00" as NSString).size(withAttributes: [.font: referenceFont]).width
        let widthLimit = referenceSize * (size.width - 32.0) / referenceWidth
        let heightLimit = referenceSize * (size.height - 2.0 * gamesScoreHeight) / referenceFont.lineHeight
        return max(1.0, floor(min(widthLimit, heightLimit)))
    }
}
