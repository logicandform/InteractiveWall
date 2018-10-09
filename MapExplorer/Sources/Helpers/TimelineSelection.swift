//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


struct TimelineSelection: Hashable {
    let index: Int
    let app: Int

    var hashValue: Int {
        return index
    }


    // MARK: Static

    static func == (lhs: TimelineSelection, rhs: TimelineSelection) -> Bool {
        return lhs.index == rhs.index
    }
}
