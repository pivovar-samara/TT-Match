//
//  MatchScreen.swift
//  TT Match
//

import SwiftUI

/// The match screen: two score buttons, the games in between, settings and the serve randomizer.
struct MatchScreen: View {

    @State private var viewModel: MatchViewModel
    @State private var volumeHandler: TTMVolumeButtonHandler?
    /// The iPhone Duo stands half open: with a horizontal fold the screen switches to the stand mode.
    @State private var isHingePartiallyOpen = false

    /// A horizontal fold to show the stand mode with, for previews.
    private let previewStandFold: CGRect?

    /// `viewModel` defaults to one for `TTMMatch.currentMatch`.
    @MainActor
    init(viewModel: MatchViewModel? = nil, previewStandFold: CGRect? = nil) {
        _viewModel = State(initialValue: viewModel ?? MatchViewModel())
        self.previewStandFold = previewStandFold
    }

    var body: some View {
        // As in the storyboard: the score area is centered in the whole window, with its top margin
        // measured from the top safe area. Padding inside the safe area would add the home indicator
        // inset at the bottom and push everything up.
        GeometryReader { proxy in
            let isCompact = Self.isCompact(proxy)
            let margin: CGFloat = isCompact ? 0.0 : 16.0
            if let fold = previewStandFold ?? (isHingePartiallyOpen ? Self.horizontalFold(proxy) : nil) {
                standContent(fold: fold, isCompact: isCompact)
            } else {
                content(isCompact: isCompact, foldLayout: Self.foldLayout(proxy))
                    .padding(.top, margin)
                    .padding(.bottom, margin + proxy.safeAreaInsets.top)
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .animation(.snappy, value: isHingePartiallyOpen)
        .modifier(HingeReader(isPartiallyOpen: $isHingePartiallyOpen))
        .background((viewModel.matchWinner?.swiftUIColor ?? .ttmBackground).ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.backgroundTap)
        .allowsHitTesting(viewModel.acceptsInput)
        .onChange(of: viewModel.isIdleTimerDisabled, initial: true) { _, isDisabled in
            UIApplication.shared.isIdleTimerDisabled = isDisabled
        }
        .onAppear(perform: startVolumeButtons)
    }

    /// Small windows (the smallest iPhones) get no vertical margins. Measured with the safe area insets,
    /// i.e. the whole window.
    private static func isCompact(_ proxy: GeometryProxy) -> Bool {
        let insets = proxy.safeAreaInsets
        let width = proxy.size.width + insets.leading + insets.trailing
        let height = proxy.size.height + insets.top + insets.bottom
        return min(width, height) < 370.0
    }

    /// The layout around a vertical fold (iPhone Duo inner display in landscape), nil without one.
    /// Inactive folds count too (the display is flat), so the layout does not jump while folding.
    private static func foldLayout(_ proxy: GeometryProxy) -> TTMFoldLayout? {
        #if canImport(SwiftUICore, _version: 8.0.85) // The iOS 27.1 SDK (Xcode 27.1)
        guard #available(iOS 27.1, *) else { return nil }
        let folds = proxy.reservedRegions(kind: .division, options: .includeInactive).map(\.frame)
        return folds.lazy.compactMap { TTMFoldLayout(containerWidth: proxy.size.width, fold: $0) }.first
        #else
        return nil
        #endif
    }

    @ViewBuilder
    private func content(isCompact: Bool, foldLayout: TTMFoldLayout?) -> some View {
        if let foldLayout {
            foldedContent(isCompact: isCompact, layout: foldLayout)
        } else {
            ZStack {
                HStack(spacing: 16.0) {
                    scoreButton(player: viewModel.leftPlayer, side: .left)
                    centerColumn(isCompact: isCompact)
                    scoreButton(player: viewModel.rightPlayer, side: .right)
                }
                .background(gameWinnerBackground)

                randomServeButton
            }
            .padding(.horizontal, 16.0)
        }
    }

    /// The score buttons meet at the fold; the games column sits at the edge opposite the camera strip.
    private func foldedContent(isCompact: Bool, layout: TTMFoldLayout) -> some View {
        HStack(spacing: TTMFoldLayout.spacing) {
            if layout.columnEdge == .leading {
                centerColumn(isCompact: isCompact)
                    .frame(width: layout.columnWidth)
            }
            ZStack {
                HStack(spacing: layout.gap) {
                    scoreButton(player: viewModel.leftPlayer, side: .left)
                        .frame(width: layout.buttonWidth)
                    scoreButton(player: viewModel.rightPlayer, side: .right)
                        .frame(width: layout.buttonWidth)
                }

                randomServeButton
            }
            if layout.columnEdge == .trailing {
                centerColumn(isCompact: isCompact)
                    .frame(width: layout.columnWidth)
            }
        }
        .background(gameWinnerBackground)
        .padding(.leading, layout.leadingPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var gameWinnerBackground: some View {
        RoundedRectangle(cornerRadius: 36.0).fill(viewModel.gameWinner?.swiftUIColor ?? .clear)
    }

    @ViewBuilder
    private var randomServeButton: some View {
        if viewModel.showsServeRandomizer {
            RandomServeButton(
                onStart: viewModel.beginServeRandomization,
                onPick: { viewModel.completeServeRandomization() },
                onFinish: viewModel.finishServeRandomization)
        }
    }

    // MARK: - Stand mode

    /// The active horizontal fold (iPhone Duo standing half open in portrait), nil without one.
    private static func horizontalFold(_ proxy: GeometryProxy) -> CGRect? {
        #if canImport(SwiftUICore, _version: 8.0.85) // The iOS 27.1 SDK (Xcode 27.1)
        guard #available(iOS 27.1, *) else { return nil }
        return proxy.reservedRegions(kind: .division).map(\.frame).first { $0.width > $0.height }
        #else
        return nil
        #endif
    }

    /// The upper half faces the players: a scoreboard to read from a distance. The lower half lies on the
    /// table: the score buttons, undo, settings and the serve randomizer.
    private func standContent(fold: CGRect, isCompact: Bool) -> some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 16.0) {
                scoreButton(player: viewModel.leftPlayer, side: .left, isInteractive: false)
                gamesStrip(isCompact: isCompact)
                    .frame(width: 48.0)
                scoreButton(player: viewModel.rightPlayer, side: .right, isInteractive: false)
            }
            .background(gameWinnerBackground)
            .padding(.top, isCompact ? 0.0 : 16.0)
            .padding(.bottom, 16.0)
            .frame(height: fold.minY)

            Color.clear
                .frame(height: fold.height)

            ZStack {
                HStack(spacing: 16.0) {
                    scoreButton(player: viewModel.leftPlayer, side: .left)
                    settingsButton
                        .padding(.bottom, isCompact ? 0.0 : 16.0)
                        .frame(width: 48.0)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    scoreButton(player: viewModel.rightPlayer, side: .right)
                }
                .background(gameWinnerBackground)

                randomServeButton
            }
            .padding(.top, 16.0)
            .padding(.bottom, isCompact ? 0.0 : 16.0)
        }
        .padding(.horizontal, 16.0)
    }

    // MARK: - Parts

    private func scoreButton(player: TTMMatchPlayer, side: ScoreButton.Side, isInteractive: Bool = true) -> some View {
        ScoreButton(
            match: viewModel.match,
            player: player,
            side: side,
            pointAnimationTrigger: side == .left ? viewModel.leftPointAnimations : viewModel.rightPointAnimations,
            onTap: { viewModel.tap(player) },
            onUndo: viewModel.undo,
            isInteractive: isInteractive)
    }

    private func centerColumn(isCompact: Bool) -> some View {
        VStack(spacing: 10.0) {
            gamesStrip(isCompact: isCompact)
            settingsButton
                .padding(.bottom, isCompact ? 0.0 : 16.0)
        }
        .frame(width: 48.0)
    }

    private func gamesStrip(isCompact: Bool) -> some View {
        GamesStrip(match: viewModel.match)
            .opacity(viewModel.showsGames ? 1.0 : 0.0)
            .padding(.top, isCompact ? 0.0 : 8.0)
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()
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

/// Tracks whether the device hinge is partially open (iOS 27.1+, devices with a hinge).
private struct HingeReader: ViewModifier {

    @Binding var isPartiallyOpen: Bool

    func body(content: Content) -> some View {
        #if canImport(SwiftUICore, _version: 8.0.85) // The iOS 27.1 SDK (Xcode 27.1)
        if #available(iOS 27.1, *) {
            content.onHingeChange { _, context in
                isPartiallyOpen = context.hinge?.status == .partiallyOpen
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#if DEBUG
/// A match for previews, stored in its own defaults suite. Scores are `[green, blue]` per game.
@MainActor
private func previewScreen(
    games: [[Int]] = [[0, 0]], firstServe: TTMMatchPlayer? = nil, gameCount: Int = 5, standFold: CGRect? = nil
) -> MatchScreen {
    let suiteName = "Preview.\(UUID().uuidString)"
    let match = TTMMatch(userDefaults: UserDefaults(suiteName: suiteName)!)
    var settings = match.settings
    settings.gameCount = gameCount
    match.settings = settings
    match.gameScores = games.map { [.green: $0[0], .blue: $0[1]] }
    match.firstServe = firstServe
    return MatchScreen(viewModel: MatchViewModel(match: match), previewStandFold: standFold)
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

#Preview("iPhone Duo inner display, landscape", traits: .fixedLayout(width: 951.0, height: 669.0)) {
    previewScreen(games: [[11, 7], [6, 8]], firstServe: .green)
}

#Preview("iPhone Duo inner display, portrait", traits: .fixedLayout(width: 669.0, height: 951.0)) {
    previewScreen(games: [[11, 7], [6, 8]], firstServe: .green)
}

/// The fold of the inner display standing half open, in a 669×951 window without safe area insets.
private let previewFold = CGRect(x: 0.0, y: 465.5, width: 669.0, height: 20.0)

#Preview("iPhone Duo stand mode", traits: .fixedLayout(width: 669.0, height: 951.0)) {
    previewScreen(games: [[11, 7], [6, 8]], firstServe: .green, standFold: previewFold)
}

#Preview("iPhone Duo stand mode, dark", traits: .fixedLayout(width: 669.0, height: 951.0)) {
    previewScreen(games: [[11, 7], [6, 8]], firstServe: .green, standFold: previewFold)
        .preferredColorScheme(.dark)
}
#endif
