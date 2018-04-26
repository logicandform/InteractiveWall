//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


struct RecordInfo: Hashable {
    let id: Int
    let map: Int
    let type: RecordType

    var hashValue: Int {
        return id.hashValue + map.hashValue + type.hashValue
    }

    static func == (lhs: RecordInfo, rhs: RecordInfo) -> Bool {
        return lhs.id == rhs.id && lhs.map == rhs.map && lhs.type == rhs.type
    }
}
