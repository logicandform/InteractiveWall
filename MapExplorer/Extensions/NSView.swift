//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum BorderPosition: CaseIterable {
    case top
    case left
    case bottom
    case right
}


extension NSView {

    @discardableResult
    func addBorder(for position: BorderPosition, thickness: CGFloat = style.defaultBorderWidth, indent: CGFloat = 0) -> CALayer {
        let border = CALayer()
        border.backgroundColor = style.defaultBorderColor.cgColor
        border.zPosition = style.windowBorderZPosition

        switch position {
        case .top:
            border.frame = CGRect(origin: CGPoint(x: 0, y: frame.height - thickness), size: CGSize(width: frame.width - indent, height: thickness))
            border.autoresizingMask = [.layerWidthSizable, .layerMinYMargin]
        case .bottom:
            border.frame = CGRect(origin: .zero, size: CGSize(width: frame.width - indent, height: thickness))
            border.autoresizingMask = .layerWidthSizable
        case .left:
            border.frame = CGRect(origin: .zero, size: CGSize(width: thickness, height: frame.height - indent))
            border.autoresizingMask = .layerHeightSizable
        case .right:
            border.frame = CGRect(origin: CGPoint(x: frame.width - thickness, y: 0), size: CGSize(width: thickness, height: frame.height - indent))
            border.autoresizingMask = [.layerHeightSizable, .layerMinXMargin]
        }

        layer?.addSublayer(border)
        return border
    }
}
