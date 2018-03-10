//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class RecordItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("RecordItemView")

    var color: NSColor? {
        didSet {
            if let hasColor = color {
                view.layer?.backgroundColor = hasColor.cgColor
            }
        }
    }


    // MARK: Life-cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }
    
}
