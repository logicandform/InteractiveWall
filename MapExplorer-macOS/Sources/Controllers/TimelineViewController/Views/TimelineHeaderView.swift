//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class TimelineHeaderView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineHeaderView")
    static let nibName = NSNib.Name(rawValue: "TimelineHeaderView")
    static let supplementaryKind = NSCollectionView.SupplementaryElementKind(rawValue: "TimelineHeaderView")

    @IBOutlet weak var textLabel: NSTextField! {
        didSet {
            textLabel.textColor = style.timelineHeaderText
        }
    }

    @IBOutlet weak var topBorder: NSView! {
        didSet {
            topBorder.wantsLayer = true
            topBorder.layer?.backgroundColor = style.timelineBorderColor.cgColor
        }
    }
}
