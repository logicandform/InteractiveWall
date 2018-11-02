//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


final class RecordNetwork {

    static func records(for type: RecordType, completion: @escaping (([Record]?) -> Void)) {
        switch type {
        case .artifact:
            artifacts(completion: completion)
        case .school:
            schools(completion: completion)
        case .event:
            events(completion: completion)
        case .organization:
            organizations(completion: completion)
        case .theme:
            themes(completion: completion)
        case .individual:
            individuals(completion: completion)
        case .collection:
            collections(completion: completion)
        }
    }


    // MARK: Artifacts

    private static func artifacts(completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getArtifacts()
        }.then { artifacts -> Void in
            completion(artifacts)
        }.catch { error in
            print(error)
            completion(nil)
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


    // MARK: Organizations

    private static func organizations(completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getOrganizations()
        }.then { organizations -> Void in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Themes

    private static func themes(completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getThemes()
        }.then { themes -> Void in
            completion(themes)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Individuals

    private static func individuals(completion: @escaping (([Individual]?) -> Void)) {
        firstly {
            try CachingNetwork.getIndividuals()
        }.then { individuals -> Void in
            completion(individuals)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Collections

    private static func collections(completion: @escaping (([RecordCollection]?) -> Void)) {
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
