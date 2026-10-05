//
//  FontExtensions.swift
//  TT Match
//

import SwiftUI

extension Font {
    static func ttmBold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }

    static func ttmHeavy(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy)
    }

    static func ttmBlack(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black)
    }
}
