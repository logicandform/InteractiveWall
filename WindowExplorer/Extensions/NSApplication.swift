//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

extension NSScreen {

    var index: Int {
        return NSScreen.screens.index(of: self) ?? 0
    }
}
