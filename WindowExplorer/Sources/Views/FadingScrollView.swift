//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class FadingScrollView: NSScrollView {

    let fadePercentage: Float = 0.035

    enum ScrollPosition {
        case top
        case bottom
        case middle
    }

    override func layout() {
        super.layout()

        let transparent = NSColor.clear.cgColor
        let opaque = style.darkBackground.cgColor

        let maskLayer = CALayer()
        maskLayer.frame = bounds

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = NSRect(x: bounds.origin.x, y: 0, width: bounds.size.width, height: bounds.size.height)
        gradientLayer.colors = [transparent, opaque, opaque, transparent]
        gradientLayer.locations = [0, NSNumber(value: fadePercentage), NSNumber(value: 1 - fadePercentage), 1]

        maskLayer.addSublayer(gradientLayer)
        self.layer?.mask = maskLayer
    }


    // MARK: API

    func checkGradient() {
        if self.isScrollActive {
            if self.hasReachedBottom {
                updateGradientProperty(position: .bottom)
            } else if self.hasReachedTop {
                updateGradientProperty(position: .top)
            } else {
                updateGradientProperty(position: .middle)
            }
        }
    }


    // MARK: Helpers

    private func updateGradientProperty(position: ScrollPosition ) {
        let transparent = NSColor.clear.cgColor
        let opaque = style.darkBackground.cgColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = NSRect(x: bounds.origin.x, y: 0, width: bounds.size.width, height: bounds.size.height)

        switch position {
        case .top:
            gradientLayer.colors = [opaque, transparent]
            gradientLayer.locations = [NSNumber(value: 1.0-0.035), 1.0]
        case .bottom:
            gradientLayer.colors = [transparent, opaque]
            gradientLayer.locations = [0.0, 0.035]
        case .middle:
            gradientLayer.colors = [transparent, opaque, opaque, transparent]
            gradientLayer.locations = [0.0, 0.035, NSNumber(value: 1.0-0.035), 1.0]
        }

        self.layer?.mask = nil
        self.layer?.mask = gradientLayer
    }
}
