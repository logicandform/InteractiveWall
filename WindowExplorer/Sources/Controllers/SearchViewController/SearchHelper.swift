//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class SearchHelper {

    static func results(for type: RecordType?, group: SearchItemDisplayable?, completion: @escaping ([SearchItemDisplayable]) -> Void) {
        guard let type = type else {
            completion([])
            return
        }

        switch group {
        case let letterGroup as LetterGroup:
            results(for: letterGroup, of: type, completion: completion)
        case let province as Province where type == .school:
            schools(for: province, completion: completion)
        default:
            results(for: type, completion: completion)
        }
    }

    static func count(for type: RecordType, group: SearchItemDisplayable, completion: @escaping (Int?) -> Void) {
        guard let letterGroup = group as? LetterGroup else {
            completion(nil)
            return
        }

        RecordNetwork.count(for: type, in: letterGroup, completion: completion)
    }


    // MARK: Helpers

    private static func results(for type: RecordType, completion: ([SearchItemDisplayable]) -> Void) {
        switch type {
        case .event, .artifact, .organization, .theme, .individual:
            completion(LetterGroup.allValues)
        case .school:
            completion(Province.allValues)
        case .collection:
            let topics = RecordManager.instance.records(for: .collection).compactMap { $0 as? RecordCollection }.filter { $0.collectionType == .topic }
            let sorted = topics.sorted { $0.title < $1.title }
            completion(sorted)
        }
    }

    private static func results(for group: LetterGroup, of type: RecordType, completion: @escaping ([SearchItemDisplayable]) -> Void) {
        RecordNetwork.records(for: type, in: group) { results in
            completion(results ?? [])
        }
    }

    private static func schools(for province: Province, completion: ([SearchItemDisplayable]) -> Void) {
        let schools = GeocodeHelper.instance.schools(for: province).sorted { $0.title < $1.title }
        completion(schools)
    }
}
