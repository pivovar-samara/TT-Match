//
//  MatchScreen.swift
//  TT Match
//

import SwiftUI

/// The match screen: two score buttons, the games in between, settings and the serve randomizer.
struct MatchScreen: View {

    @State private var viewModel: MatchViewModel
    @State private var volumeHandler: TTMVolumeButtonHandler?
    @State private var isRandomizingServe = false
    @State private var showsGameCountDialog = false
    @State private var showsResetDialog = false

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
        .background((viewModel.matchWinner?.swiftUIColor ?? .white).ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture(perform: viewModel.backgroundTap)
        .allowsHitTesting(!viewModel.isInputLocked)
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

            if viewModel.showsServeRandomizer || isRandomizingServe {
                RandomServeButton(
                    isEnabled: viewModel.canRandomizeServe,
                    onStart: {
                        isRandomizingServe = true
                        viewModel.beginServeRandomization()
                    },
                    onPick: { viewModel.completeServeRandomization() },
                    onFinish: { isRandomizingServe = false })
            }
        }
    }

    // MARK: - Parts

    private func scoreButton(player: TTMMatchPlayer, side: ScoreButton.Side) -> some View {
        ScoreButton(
            match: viewModel.match,
            player: player,
            side: side,
            pointAnimationTrigger: viewModel.pointAnimations[player, default: 0],
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
            Button {
                if mode == .reset {
                    showsResetDialog = true
                } else {
                    showsGameCountDialog = true
                }
            } label: {
                settingsLabel(mode)
                    .frame(width: 48.0, height: 48.0)
                    .background(Circle().fill(settingsBackground(mode)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings")
            .confirmationDialog(Text(verbatim: ""), isPresented: $showsGameCountDialog, titleVisibility: .hidden) {
                Button(L("MatchSettings_3games")) { viewModel.setGameCount(3) }
                Button(L("MatchSettings_5games")) { viewModel.setGameCount(5) }
                Button(L("MatchSettings_7games")) { viewModel.setGameCount(7) }
                Button(L("Cancel"), role: .cancel) {}
            }
            .confirmationDialog(L("Shake_ActionSheet_Title"), isPresented: $showsResetDialog, titleVisibility: .visible) {
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
            viewModel.hardwareTap(viewModel.rightPlayer)
        }, downBlock: {
            viewModel.hardwareTap(viewModel.leftPlayer)
        })
        handler.start(true)
        volumeHandler = handler
    }
}

#Preview {
    MatchScreen(viewModel: MatchViewModel(match: TTMMatch(userDefaults: UserDefaults(suiteName: "Preview")!)))
}
