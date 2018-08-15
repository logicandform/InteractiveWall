//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineTailView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineTailView")
    static let nibName = NSNib.Name(rawValue: "TimelineTailView")
    static let supplementaryKind = NSCollectionView.SupplementaryElementKind(rawValue: "TimelineTailView")

    private var year: Int!
    private var tails = [Tail]() {
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

        let tailsEnding = tails.filter { $0.lastYear == year }.count
        let endingWidth = Constants.yearWidth - CGFloat(tailsEnding) * style.timelineInterTailMargin

        for (index, tail) in tails.enumerated() {
            let y = CGFloat(index * 5)
            let width = tail.lastYear == year ? endingWidth : Constants.yearWidth
            let line = NSBezierPath(rect: CGRect(x: 0, y: y, width: width, height: style.timelineTailWidth))
            line.fill()
        }
    }


    // MARK: API

    func set(_ tails: [Tail], year: Int) {
        self.tails = tails
        self.year = year
    }
}
