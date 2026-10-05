//
//  GamesStrip.swift
//  TT Match
//

import SwiftUI

/// One row per game of the match: finished games show the score in the winner's color.
struct GamesStrip: View {

    let match: TTMMatch

    var body: some View {
        let players = match.players
        VStack(spacing: 0.0) {
            ForEach(0..<match.settings.gameCount, id: \.self) { index in
                GameRow(match: match, gameIndex: index, players: players)
            }
        }
    }
}

struct GameRow: View {

    let match: TTMMatch
    let gameIndex: Int
    /// Left and right player.
    let players: [TTMMatchPlayer]

    var body: some View {
        HStack(spacing: 0.0) {
            if let scores {
                label(scores.left, isWinner: scores.left > scores.right)
                label(scores.right, isWinner: scores.right > scores.left)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 4.0).fill(backgroundColor))
        .padding(.vertical, 6.0)
        .frame(height: 32.0)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("game.\(gameIndex)")
        .accessibilityValue(Text(verbatim: scores.map { "\($0.left)-\($0.right)" } ?? ""))
    }

    private func label(_ score: Int, isWinner: Bool) -> some View {
        Text(String(score))
            .font(.ttmHeavy(14.0))
            .foregroundStyle(.white)
            .opacity(isWinner ? 1.0 : 0.5)
            .frame(maxWidth: .infinity)
    }

    /// Scores of a finished game, nil while the game is not finished.
    private var scores: (left: Int, right: Int)? {
        let lastIndex = match.gameScores.count - 1
        guard gameIndex < lastIndex || (gameIndex == lastIndex && match.gameFinished) else { return nil }
        let game = match.gameScores[gameIndex]
        return (game[players[0]] ?? 0, game[players[1]] ?? 0)
    }

    private var backgroundColor: Color {
        if match.gameFinished {
            return .white.opacity(0.25)
        }
        guard let scores else {
            return .ttmGray.opacity(0.5)
        }
        return scores.left > scores.right ? players[0].swiftUIColor : players[1].swiftUIColor
    }
}
