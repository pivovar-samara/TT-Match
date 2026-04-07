//
//  UIImageExtensions.swift
//  TT Match
//
//  Created by Ilya Khokhlov on 04.05.16.
//

import UIKit

extension UIImage {
    static func imageFromColor(_ color: UIColor) -> UIImage {
        let scale = UIScreen.main.scale
        let size = CGSize(width: 1.0 / scale, height: 1.0 / scale)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func tinted(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: .zero, size: self.size)
        return UIGraphicsImageRenderer(size: self.size).image { ctx in
            // 1. Fill the canvas with the tint colour.
            color.setFill()
            ctx.fill(rect)
            // 2. Draw the image with .destinationIn: keeps the destination
            //    (colour fill) only where the source (image) has alpha > 0.
            //    This correctly cuts the colour to the image's shape, not its
            //    bounding rectangle.
            self.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
        }
    }
}
