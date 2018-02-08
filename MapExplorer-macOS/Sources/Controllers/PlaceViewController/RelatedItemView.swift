//  Copyright © 2018 JABT. All rights reserved.

import Cocoa

class RelatedItem: NSView {
    static let interfaceIdentifier = NSUserInterfaceItemIdentifier(rawValue: "RelatedItem")
    static let nibName = NSNib.Name(rawValue: "RelatedItem")

    override func awakeFromNib() {
        super.awakeFromNib()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
}
