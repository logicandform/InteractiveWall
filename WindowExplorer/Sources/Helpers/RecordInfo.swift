//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


struct RecordInfo: Hashable {
    let id: Int
    let app: Int
    let type: RecordType

    var hashValue: Int {
        return id.hashValue + app.hashValue + type.hashValue
    }

    static func == (lhs: RecordInfo, rhs: RecordInfo) -> Bool {
        return lhs.id == rhs.id && lhs.app == rhs.app && lhs.type == rhs.type
    }
}
