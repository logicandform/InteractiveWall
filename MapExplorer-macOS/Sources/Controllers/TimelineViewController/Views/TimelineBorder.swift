//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


class TimelineBorder: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier(rawValue: "TimelineBorder")


    // MARK: Init

    override func awakeFromNib() {
        super.awakeFromNib()
        view.wantsLayer = true
        view.layer?.backgroundColor = style.borderColor.cgColor
    }


    // MARK: API

    func set(frame: CGRect) {
        view.frame = frame
    }
}
