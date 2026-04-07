//
//  UIColorExtensions.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import UIKit

extension UIColor {
    @nonobjc static let ttmBlueColor = UIColor(red: 0.0, green: 145.0/255.0, blue: 234.0/255.0, alpha: 1.0)
    @nonobjc static let ttmGreenColor = UIColor(red: 25.0/255.0, green: 174.0/255.0, blue: 0.0, alpha: 1.0)
    @nonobjc static let ttmGrayColor = UIColor(red: 120.0/255.0, green: 144.0/255.0, blue: 156.0/255.0, alpha: 1.0)
}

extension UIColor {
    func opaqueColor(_ alpha: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(
            red:   alpha * r + (1.0 - alpha),
            green: alpha * g + (1.0 - alpha),
            blue:  alpha * b + (1.0 - alpha),
            alpha: alpha * a + (1.0 - alpha)
        )
    }
}
