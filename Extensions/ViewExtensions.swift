//
//  ViewExtensions.swift
//  TT Match
//

import SwiftUI

extension View {
    /// A circular control background: Liquid Glass on iOS 26 and later, `fallback` fill before.
    @ViewBuilder
    func ttmCircleBackground(_ fallback: Color) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: .circle)
        } else {
            background(Circle().fill(fallback))
        }
    }
}
