//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineTailView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineTailView")
    static let nibName = "TimelineTailView"
    static let supplementaryKind = "TimelineTailView"

    private var layers = [Layer]()

    private struct Constants {
        static let countTitleMargins: CGFloat = 2
        static let minimumLayersForTitle = 2
    }


    // MARK: Overrides

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        var needsTitle = true

        for (index, layer) in layers.enumerated() {
            let baseHeight = style.timelineTailMargin
            let layerHeight = CGFloat(index) * (style.timelineTailWidth + style.timelineTailMargin)
            let y = baseHeight + layerHeight

            if let first = layer.lines.first, index >= Constants.minimumLayersForTitle, needsTitle {
                let title = NSAttributedString(string: index.description, attributes: style.timelineDateAttributes)
                let titleWidth = title.size().width + 2 * Constants.countTitleMargins
                if first.start > titleWidth {
                    let baseline = y - style.timelineTailMargin
                    title.draw(at: CGPoint(x: Constants.countTitleMargins, y: baseline))
                    needsTitle = false
                }
            }
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

        if layers.count >= Constants.minimumLayersForTitle, needsTitle {
            let title = NSAttributedString(string: layers.count.description, attributes: style.timelineDateAttributes)
            let baseHeight = style.timelineTailMargin
            let layerHeight = CGFloat(layers.count) * (style.timelineTailWidth + style.timelineTailMargin)
            let baseline = baseHeight + layerHeight - style.timelineTailMargin
            title.draw(at: CGPoint(x: Constants.countTitleMargins, y: baseline))
        }
    }


    // MARK: API

    func set(_ layers: [Layer]) {
        self.layers = layers
        needsDisplay = true
    }
}
