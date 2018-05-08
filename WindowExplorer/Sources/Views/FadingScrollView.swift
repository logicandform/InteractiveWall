//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class FadingScrollView: NSScrollView {

    let fadePercentage: Float = 0.035

    override func layout() {
        super.layout()

        let transparent = NSColor.clear.cgColor
        let opaque = style.darkBackground.cgColor

        let maskLayer = CALayer()
        maskLayer.frame = bounds

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = NSMakeRect(bounds.origin.x, 0, bounds.size.width, bounds.size.height)
        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [0, NSNumber(value: fadePercentage), NSNumber(value: 1 - fadePercentage), 1]

        maskLayer.addSublayer(gradientLayer)
        self.layer?.mask = maskLayer
    }
}
