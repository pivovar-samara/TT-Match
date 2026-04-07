//
//  UIFontExtensions.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import UIKit

extension UIFont {
    public class func ttmFontUltraLightOfSize(_ fontSize: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: fontSize, weight: .ultraLight)
    }

    public class func ttmFontRegularOfSize(_ fontSize: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: fontSize)
    }

    public class func ttmFontMediumOfSize(_ fontSize: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: fontSize, weight: .medium)
    }

    public class func ttmFontBoldOfSize(_ fontSize: CGFloat) -> UIFont {
        return UIFont.boldSystemFont(ofSize: fontSize)
    }

    public class func ttmFontHeavyOfSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .heavy)
    }

    public class func ttmFontBlackOfSize(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .black)
    }
}
