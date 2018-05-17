//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class FadingScrollView: NSScrollView {

    let fadePercentage: Float = 0.035


    enum ScrollPosition {
        case top
        case bottom
        case middle
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


    // MARK: Overrides

    override func layout() {
        super.layout()
        checkGradient()
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
            gradientLayer.locations = [NSNumber(value: 1.0 - fadePercentage), 1.0]
        case .bottom:
            gradientLayer.colors = [transparent, opaque]
            gradientLayer.locations = [0.0, NSNumber(value:fadePercentage)]
        case .middle:
            gradientLayer.colors = [transparent, opaque, opaque, transparent]
            gradientLayer.locations = [0.0, NSNumber(value: fadePercentage), NSNumber(value: 1.0 - fadePercentage), 1.0]
        }

        self.layer?.mask = gradientLayer
    }
}
