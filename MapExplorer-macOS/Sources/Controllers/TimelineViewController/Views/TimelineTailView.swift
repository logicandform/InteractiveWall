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

        // Check if tail is selected before setting color
        RecordType.school.color.setFill()

        for (index, layer) in layers.enumerated() {
            let y = CGFloat(index) * style.timelineInterTailMargin
            for line in layer.lines {
                let path = NSBezierPath(rect: CGRect(x: line.start, y: y, width: line.width, height: style.timelineTailWidth))
                path.fill()
            }
            for drop in layer.drops {
                let path = NSBezierPath(rect: CGRect(x: drop.x, y: y - style.timelineTailGap, width: style.timelineTailWidth, height: style.timelineInterTailMargin + style.timelineTailWidth))
                path.fill()
            }
        }
    }


    // MARK: API

    func set(_ layers: [Layer]) {
        self.layers = layers
    }
}
