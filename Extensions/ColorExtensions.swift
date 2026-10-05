//
//  ColorExtensions.swift
//  TT Match
//

import SwiftUI

extension Color {
    static let ttmBlue = Color(uiColor: .ttmBlueColor)
    static let ttmGreen = Color(uiColor: .ttmGreenColor)
    static let ttmGray = Color(uiColor: .ttmGrayColor)
    /// Screen background: white in light mode, black in dark mode.
    static let ttmBackground = Color(uiColor: .systemBackground)
}

extension TTMMatchPlayer {
    var swiftUIColor: Color {
        switch self {
        case .green:
            return .ttmGreen
        case .blue:
            return .ttmBlue
        }
    }
}
