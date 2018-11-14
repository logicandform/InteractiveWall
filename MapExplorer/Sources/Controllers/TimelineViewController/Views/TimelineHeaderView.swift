//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineHeaderView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineHeaderView")
    static let nibName = "TimelineHeaderView"
    static let supplementaryKind = "TimelineHeaderView"

    @IBOutlet private weak var textLabel: NSTextField! {
        didSet {
            textLabel.textColor = style.timelineHeaderText
        }
    }

    @IBOutlet private weak var topBorder: NSView! {
        didSet {
            topBorder.wantsLayer = true
            topBorder.layer?.backgroundColor = style.timelineBorderColor.cgColor
        }
    }

    private struct Constants {
        static let tickHeight: CGFloat = 10
        static let tickWidth: CGFloat = 2
    }


    // MARK: API

    func set(text: String) {
        textLabel.stringValue = text
    }


    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        style.timelineBorderColor.setFill()
        let tick = CGRect(x: style.timelineHeaderOffset, y: frame.height - Constants.tickHeight, width: Constants.tickWidth, height: Constants.tickHeight)
        let path = NSBezierPath(rect: tick)
        path.fill()
    }
}
