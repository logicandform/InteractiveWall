//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


private enum ScrollPosition {
    case top
    case bottom
    case middle
    case none
}


class FadingScrollView: NSScrollView {

    private var currentPosition = ScrollPosition.middle

    private struct Constants {
        static let fadePercentage = 0.035
    }


    // MARK: API

    func updateGradient(forced: Bool = false, with delta: CGFloat = 0, height: CGFloat? = nil) {
        if !canScroll(contentHeight: height) {
            updateGradientProperty(for: .none, forced: forced)
            return
        } else if height != nil {
            updateGradientProperty(for: .top, forced: forced)
            return
        }

        if hasReachedBottom(with: delta) {
            updateGradientProperty(for: .bottom, forced: forced)
        } else if hasReachedTop(with: delta) {
            updateGradientProperty(for: .top, forced: forced)
        } else {
            updateGradientProperty(for: .middle, forced: forced)
        }
    }


    // MARK: Overrides

    override func layout() {
        super.layout()
        updateGradient()
    }


    // MARK: Helpers

    private func updateGradientProperty(for position: ScrollPosition, forced: Bool) {
        if position == currentPosition, !forced {
            return
        }

        currentPosition = position
        let transparent = CGColor.clear
        let opaque = CGColor.black
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = NSRect(x: bounds.origin.x, y: 0, width: bounds.size.width, height: bounds.size.height)

        switch position {
        case .top:
            gradientLayer.colors = [opaque, transparent]
            gradientLayer.locations = [NSNumber(value: 1 - Constants.fadePercentage), 1]
        case .bottom:
            gradientLayer.colors = [transparent, opaque]
            gradientLayer.locations = [0, NSNumber(value: Constants.fadePercentage)]
        case .middle:
            gradientLayer.colors = [transparent, opaque, opaque, transparent]
            gradientLayer.locations = [0, NSNumber(value: Constants.fadePercentage), NSNumber(value: 1 - Constants.fadePercentage), 1]
        case .none:
            gradientLayer.colors = [opaque, opaque]
            gradientLayer.locations = [0, 1]
        }

        layer?.mask = gradientLayer
    }
}
