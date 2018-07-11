//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class FadingScrollView: NSScrollView {

    private struct Constants {
        static let fadePercentage = 0.1
    }


    // MARK: Overrides

    override func layout() {
        super.layout()
        wantsLayer = true
        let transparent = NSColor.clear.cgColor
        let opaque = style.darkBackgroundOpaque.cgColor
        let gradientLayer = CAGradientLayer()
        let test = bounds
        gradientLayer.frame = bounds
        //        gradientLayer.frame = NSRect(x: scrollView.bounds.origin.x, y: 0, width: scrollView.bounds.width, height: scrollView.bounds.height)
//        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [0.0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1.0 - Constants.fadePercentage), 1.0]
        gradientLayer.transform = CATransform3DMakeRotation(CGFloat.pi / 2, 0, 0, 1)
        layer?.mask = gradientLayer
    }
}
