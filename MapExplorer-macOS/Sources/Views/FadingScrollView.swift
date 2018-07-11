//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class FadingScrollView: NSScrollView {

    private struct Constants {
        static let fadePercentage = 0.1
    }


    func gradient(on: Bool) {
        switch on {
        case true:
            wantsLayer = true
            let transparent = NSColor.clear.cgColor
            let opaque = style.darkBackgroundOpaque.cgColor
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = bounds
            gradientLayer.colors = [transparent, opaque, opaque, transparent]
            gradientLayer.locations = [0.0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1.0 - Constants.fadePercentage), 1.0]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            layer?.mask = gradientLayer
        case false:
            layer?.mask = nil
        }
    }
}
