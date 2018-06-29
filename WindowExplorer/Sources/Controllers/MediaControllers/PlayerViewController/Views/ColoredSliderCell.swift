//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


class ColoredSliderCell: NSSliderCell {

    var rounded = false
    var leadingColor = NSColor.blue
    var trailingColor = NSColor.darkGray

    private struct Constants {
        static let verticalOffset: CGFloat = 0.5
    }


    // MARK: Init

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    // MARK: Drawing

    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let currentPosition = CGFloat((doubleValue - minValue) / (maxValue - minValue))
        let barRadius = rounded ? rect.height / 2 : 0
        let leadingRectWidth = currentPosition * rect.width
        let barHeight: CGFloat = 2
        let origin = CGPoint(x: rect.origin.x, y: rect.origin.y + barHeight/2 + Constants.verticalOffset)

        let totalRect = CGRect(origin: origin, size: CGSize(width: rect.size.width, height: barHeight))
        let trailingRectPath = NSBezierPath(roundedRect: totalRect, xRadius: barRadius, yRadius: barRadius)
        trailingColor.setFill()
        trailingRectPath.fill()

        let leadingRect = CGRect(origin: origin, size: CGSize(width: leadingRectWidth, height: barHeight))
        let leadingRectPath = NSBezierPath(roundedRect: leadingRect, xRadius: barRadius, yRadius: barRadius)
        leadingColor.setFill()
        leadingRectPath.fill()
    }
}
