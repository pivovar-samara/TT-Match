//
//  MatchScreen.swift
//  TT Match
//

import SwiftUI

/// The match screen: two score buttons, the games in between, settings and the serve randomizer.
struct MatchScreen: View {

    @State private var viewModel: MatchViewModel
    @State private var volumeHandler: TTMVolumeButtonHandler?

    /// `viewModel` defaults to one for `TTMMatch.currentMatch`.
    @MainActor
    init(viewModel: MatchViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? MatchViewModel())
    }

    var body: some View {
        // As in the storyboard: the score area is centered in the whole window, with its top margin
        // measured from the top safe area. Padding inside the safe area would add the home indicator
        // inset at the bottom and push everything up.
        GeometryReader { proxy in
            let margin: CGFloat = IS_SMALL_SCREEN ? 0.0 : 16.0
            content
                .padding(.horizontal, 16.0)
                .padding(.top, margin)
                .padding(.bottom, margin + proxy.safeAreaInsets.top)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .background((viewModel.matchWinner?.swiftUIColor ?? .ttmBackground).ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.backgroundTap)
        .allowsHitTesting(viewModel.acceptsInput)
        .onChange(of: viewModel.isIdleTimerDisabled, initial: true) { _, isDisabled in
            UIApplication.shared.isIdleTimerDisabled = isDisabled
        }
        .onAppear(perform: startVolumeButtons)
    }

    private var content: some View {
        ZStack {
            HStack(spacing: 16.0) {
                scoreButton(player: viewModel.leftPlayer, side: .left)
                centerColumn
                scoreButton(player: viewModel.rightPlayer, side: .right)
            }
            .background(RoundedRectangle(cornerRadius: 36.0).fill(viewModel.gameWinner?.swiftUIColor ?? .clear))

            if viewModel.showsServeRandomizer {
                RandomServeButton(
                    onStart: viewModel.beginServeRandomization,
                    onPick: { viewModel.completeServeRandomization() },
                    onFinish: viewModel.finishServeRandomization)
            }
        }
    }

    // MARK: - Parts

    private func scoreButton(player: TTMMatchPlayer, side: ScoreButton.Side) -> some View {
        ScoreButton(
            match: viewModel.match,
            player: player,
            side: side,
            pointAnimationTrigger: side == .left ? viewModel.leftPointAnimations : viewModel.rightPointAnimations,
            onTap: { viewModel.tap(player) },
            onUndo: viewModel.undo)
    }

    private var centerColumn: some View {
        VStack(spacing: 10.0) {
            GamesStrip(match: viewModel.match)
                .opacity(viewModel.showsGames ? 1.0 : 0.0)
                .padding(.top, IS_SMALL_SCREEN ? 0.0 : 8.0)
                .frame(maxHeight: .infinity, alignment: .top)
                .clipped()
            settingsButton
                .padding(.bottom, IS_SMALL_SCREEN ? 0.0 : 16.0)
        }
        .frame(width: 48.0)
    }

    @ViewBuilder
    private var settingsButton: some View {
        let mode = viewModel.settingsMode
        if mode == .hidden {
            Color.clear
                .frame(width: 48.0, height: 48.0)
        } else {
            Button(action: viewModel.showSettings) {
                settingsLabel(mode)
                    .frame(width: 48.0, height: 48.0)
                    .ttmCircleBackground(settingsBackground(mode))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L(mode == .reset ? "Accessibility_ResetMatch" : "Accessibility_MatchLength"))
            .accessibilityValue(settingsAccessibilityValue(mode))
            .accessibilityIdentifier("settings")
            .confirmationDialog(Text(verbatim: ""), isPresented: isPresenting(.gameCount), titleVisibility: .hidden) {
                Button(L("MatchSettings_3games")) { viewModel.setGameCount(3) }
                Button(L("MatchSettings_5games")) { viewModel.setGameCount(5) }
                Button(L("MatchSettings_7games")) { viewModel.setGameCount(7) }
                Button(L("Cancel"), role: .cancel) {}
            }
            .confirmationDialog(L("Shake_ActionSheet_Title"), isPresented: isPresenting(.reset), titleVisibility: .visible) {
                Button(L("Shake_ActionSheet_Confirm"), role: .destructive, action: viewModel.resetMatch)
                Button(L("Cancel"), role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private func settingsLabel(_ mode: TTMSettingsMode) -> some View {
        switch mode {
        case .gameCount(let gameCount):
            Text(String(gameCount))
                .font(.ttmBlack(18.0))
                .foregroundStyle(Color.ttmGray)
        case .reset, .hidden:
            Image("settings")
                .renderingMode(.template)
                .foregroundStyle(viewModel.gameWinner != nil ? Color.white.opacity(0.5) : Color.ttmGray)
        }
    }

    private func isPresenting(_ dialog: TTMSettingsDialog) -> Binding<Bool> {
        Binding(
            get: { viewModel.presentedDialog == dialog },
            set: { isPresented in
                if !isPresented && viewModel.presentedDialog == dialog {
                    viewModel.presentedDialog = nil
                }
            })
    }

    /// The game count while it can be chosen.
    private func settingsAccessibilityValue(_ mode: TTMSettingsMode) -> String {
        if case .gameCount(let gameCount) = mode {
            return String(gameCount)
        }
        return ""
    }

    private func settingsBackground(_ mode: TTMSettingsMode) -> Color {
        if mode == .reset && viewModel.gameWinner != nil {
            return .clear
        }
        return .ttmGray.opacity(0.2)
    }

    // MARK: - Volume buttons

    private func startVolumeButtons() {
        guard volumeHandler == nil else { return }
        let viewModel = self.viewModel
        let handler = TTMVolumeButtonHandler(up: {
            viewModel.tap(viewModel.rightPlayer)
        }, downBlock: {
            viewModel.tap(viewModel.leftPlayer)
        })
        handler.start(true)
        volumeHandler = handler
    }
}

#if DEBUG
/// A match for previews, stored in its own defaults suite. Scores are `[green, blue]` per game.
@MainActor
private func previewScreen(games: [[Int]] = [[0, 0]], firstServe: TTMMatchPlayer? = nil, gameCount: Int = 5) -> MatchScreen {
    let suiteName = "Preview.\(UUID().uuidString)"
    let match = TTMMatch(userDefaults: UserDefaults(suiteName: suiteName)!)
    var settings = match.settings
    settings.gameCount = gameCount
    match.settings = settings
    match.gameScores = games.map { [.green: $0[0], .blue: $0[1]] }
    match.firstServe = firstServe
    return MatchScreen(viewModel: MatchViewModel(match: match))
}

#Preview("Before the match", traits: .landscapeLeft) {
    previewScreen()
}

#Preview("In a game", traits: .landscapeLeft) {
    previewScreen(games: [[11, 7], [6, 8]], firstServe: .green)
}

#Preview("Game finished", traits: .landscapeLeft) {
    previewScreen(games: [[11, 7], [9, 11]], firstServe: .green)
}

#Preview("Match finished", traits: .landscapeLeft) {
    previewScreen(games: [[11, 7], [9, 11], [11, 4], [11, 9]], firstServe: .green)
}

#Preview("In a game, dark", traits: .landscapeLeft) {
    previewScreen(games: [[11, 7], [6, 8]], firstServe: .green)
        .preferredColorScheme(.dark)
}
#endif
