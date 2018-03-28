//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


struct RecordInfo: Hashable {
    var hashValue: Int {
        return recordId.hashValue + type.hashValue + mapId.hashValue
    }

    static func ==(lhs: RecordInfo, rhs: RecordInfo) -> Bool {
        return
            lhs.recordId == rhs.recordId &&
                lhs.type == rhs.type &&
                lhs.mapId == rhs.mapId
    }

    let recordId: Int
    let mapId: Int
    let type: RecordType
}

