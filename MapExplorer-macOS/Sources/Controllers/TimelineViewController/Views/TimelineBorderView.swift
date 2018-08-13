//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineBorderView: NSView {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineBorderView")
    static let nibName = NSNib.Name(rawValue: "TimelineBorderView")
    static let supplementaryKind = NSCollectionView.SupplementaryElementKind(rawValue: "TimelineBorderView")

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = style.timelineBorderColor.cgColor
    }
}
