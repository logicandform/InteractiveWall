//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineTailView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineTailView")
    static let nibName = NSNib.Name(rawValue: "TimelineTailView")
    static let supplementaryKind = NSCollectionView.SupplementaryElementKind(rawValue: "TimelineTailView")

    private var layers = [Layer]() {
        didSet {
            needsDisplay = true
        }
    }

    private struct Constants {
        static let yearWidth: CGFloat = 192
    }


    // MARK: Overrides

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        for (index, layer) in layers.enumerated() {
            let baseHeight = style.timelineTailMargin
            let layerHeight = CGFloat(index) * (style.timelineTailWidth + style.timelineTailMargin)
            let y = baseHeight + layerHeight

            for line in layer.lines {
                let color = line.event.highlighted ? line.event.type.color : style.timelineTailColor
                color.setFill()
                let path = NSBezierPath(rect: CGRect(x: line.start, y: y, width: line.width, height: style.timelineTailWidth))
                path.fill()
            }
            for drop in layer.drops {
                let color = drop.event.highlighted ? drop.event.type.color : style.timelineTailColor
                color.setFill()
                let path = NSBezierPath(rect: CGRect(x: drop.x, y: y - style.timelineTailGap, width: style.timelineTailWidth, height: style.timelineTailGap + style.timelineTailWidth))
                path.fill()
            }
            NSColor.white.setFill()
            for marker in layer.markers {
                let radius = style.timelineTailMarkerWidth
                let path = NSBezierPath(rect: CGRect(x: marker.x, y: y, width: radius, height: radius))
                path.fill()
            }
        }
    }


    // MARK: API

    func set(_ layers: [Layer]) {
        self.layers = layers
    }
}
