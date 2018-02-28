//  Copyright © 2018 JABT. All rights reserved.

import AppKit

extension NSImage {

    convenience init?(named name: String) {
        self.init(named: NSImage.Name(rawValue: name))
    }
}
