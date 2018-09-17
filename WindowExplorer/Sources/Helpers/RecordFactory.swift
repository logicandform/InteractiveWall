//  Copyright © 2018 JABT. All rights reserved.

import Foundation


/// Provides records from different sources depending on the request.
final class RecordFactory {

    static func record(for type: RecordType, id: Int) -> Record? {
        return RecordManager.instance.record(for: type, id: id)
    }

    static func records(for type: RecordType) -> [Record] {
        return RecordManager.instance.records(for: type)
    }

    static func records(for type: RecordType, ids: [Int]) -> [Record] {
        return RecordManager.instance.records(for: type, ids: ids)
    }

    static func records(for type: RecordType, in group: LetterGroup, completion: @escaping ([Record]?) -> Void) {
        RecordNetwork.records(for: type, in: group, completion: completion)
    }

    static func count(for type: RecordType, in group: LetterGroup, completion: @escaping (Int?) -> Void) {
        RecordNetwork.count(for: type, in: group, completion: completion)
    }
}
