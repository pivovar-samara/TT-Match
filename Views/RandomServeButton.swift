//
//  RandomServeButton.swift
//  TT Match
//

import SwiftUI

/// Picks the first server at random: the arrows spin, then fly apart while the match starts.
struct RandomServeButton: View {

    /// The spin is about to start. Returns false when the randomization must not start.
    let onStart: () -> Bool
    /// Time to pick the server (shortly after the spin, while the arrows fly apart).
    let onPick: () -> Void
    /// The animation is over; the button can go away.
    let onFinish: () -> Void

    @State private var isAnimating = false
    @State private var isExploding = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Angle = .zero
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 140.0, height: 140.0)
                .opacity(isExploding ? 0.0 : 1.0)

            Button(action: start) {
                Image("swap_arrows")
                    .renderingMode(.template)
                    .foregroundStyle(Color.ttmGray)
                    .frame(width: 128.0, height: 128.0)
                    .background(Circle().fill(Color(uiColor: UIColor.ttmGrayColor.opaqueColor(0.2))))
            }
            .buttonStyle(.plain)
            .scaleEffect(scale)
            .rotationEffect(rotation)
            .opacity(opacity)
            .accessibilityIdentifier("randomServe")
        }
    }

    private func start() {
        guard !isAnimating, onStart() else { return }
        isAnimating = true

        withAnimation(.easeInOut(duration: 1.5)) {
            scale = 2.0
            rotation = .degrees(180.0)
        } completion: {
            isExploding = true
            delay(0.25) {
                onPick()
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                scale = 10.0
                opacity = 0.0
            } completion: {
                // Back to the initial state, in case this view stays on screen (the serve is undecided again).
                isAnimating = false
                isExploding = false
                scale = 1.0
                rotation = .zero
                opacity = 1.0
                onFinish()
            }
        }
    }
}
