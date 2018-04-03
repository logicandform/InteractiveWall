//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

class ColoredSliderCell: NSSliderCell {

    var rounded = false
    var leadingColor = NSColor.blue
    var trailingColor = NSColor.darkGray


    // MARK: Init

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    // MARK: Drawing

    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let currentPosition = CGFloat((doubleValue - minValue) / (maxValue - minValue))
        let barRadius = rounded ? rect.height / 2 : 0
        let leadingRectWidth = currentPosition * rect.width
        let leadingRect = CGRect(origin: rect.origin, size: CGSize(width: leadingRectWidth, height: rect.height))

        let trailingRectPath = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        trailingColor.setFill()
        trailingRectPath.fill()

        let leadingRectPath = NSBezierPath(roundedRect: leadingRect, xRadius: barRadius, yRadius: barRadius)
        leadingColor.setFill()
        leadingRectPath.fill()
    }
}
