//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


final class RecordNetwork {

    static func records(for type: RecordType, completion: @escaping (([Record]?) -> Void)) {
        switch type {
        case .school:
            schools(completion: completion)
        case .event:
            events(completion: completion)
        case .collection:
            collections(completion: completion)
        }
    }


    // MARK: Schools

    private static func schools(completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getSchools()
        }.then { schools -> Void in
            completion(schools)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Events

    private static func events(completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getEvents()
        }.then { events -> Void in
            completion(events)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Collections

    private static func collections(completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getCollections()
        }.then { collections -> Void in
            completion(collections)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }
}
