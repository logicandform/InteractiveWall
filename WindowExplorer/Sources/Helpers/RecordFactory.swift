//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


final class RecordFactory {

    static func record(for type: RecordType, id: Int, completion: @escaping ((Record?) -> Void)) {
        switch type {
        case .artifact:
            artifact(id: id, completion: completion)
        case .school:
            school(id: id, completion: completion)
        case .event:
            event(id: id, completion: completion)
        case .organization:
            organization(id: id, completion: completion)
        case .theme:
            theme(id: id, completion: completion)
        case .collection:
            collection(id: id, completion: completion)
        }
    }

    static func records(for type: RecordType, ids: [Int], completion: @escaping (([Record]?) -> Void)) {
        switch type {
        case .artifact:
            artifacts(ids: ids, completion: completion)
        case .school:
            schools(ids: ids, completion: completion)
        case .event:
            events(ids: ids, completion: completion)
        case .organization:
            organizations(ids: ids, completion: completion)
        case .theme:
            themes(ids: ids, completion: completion)
        case .collection:
            completion(nil)
        }
    }

    static func records(for type: RecordType, in group: LetterGroup, completion: @escaping (([Record]?) -> Void)) {
        switch type {
        case .artifact:
            artifacts(for: group, completion: completion)
        case .school:
            schools(for: group, completion: completion)
        case .event:
            events(for: group, completion: completion)
        case .organization:
            organizations(for: group, completion: completion)
        case .theme:
            themes(for: group, completion: completion)
        case .collection:
            completion(nil)
        }
    }

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
        case .collection:
            collections(completion: completion)
        }
    }

    static func count(for type: RecordType, in group: LetterGroup, completion: @escaping ((Int?) -> Void)) {
        firstly {
            try CachingNetwork.getCount(of: type, in: group)
        }.then { count -> Void in
            completion(count)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Artifacts

    private static func artifact(id: Int, completion: @escaping ((Record?) -> Void)) {
        firstly {
            CachingNetwork.getArtifact(by: id)
        }.then { artifact -> Void in
            completion(artifact)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func artifacts(ids: [Int], completion: @escaping (([Record]?) -> Void)) {
        let promises = ids.map { CachingNetwork.getArtifact(by: $0) }

        firstly {
            when(fulfilled: promises)
        }.then { artifacts -> Void in
            completion(artifacts)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

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

    private static func artifacts(for group: LetterGroup, completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getArtifacts(in: group)
        }.then { artifacts -> Void in
            completion(artifacts)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Schools

    private static func school(id: Int, completion: @escaping ((Record?) -> Void)) {
        firstly {
            CachingNetwork.getSchool(by: id)
        }.then { school -> Void in
            completion(school)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func schools(ids: [Int], completion: @escaping (([Record]?) -> Void)) {
        let promises = ids.map { CachingNetwork.getTheme(by: $0) }

        firstly {
            when(fulfilled: promises)
        }.then { schools -> Void in
            completion(schools)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

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

    private static func schools(for group: LetterGroup, completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getSchools(in: group)
        }.then { schools -> Void in
            completion(schools)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Events

    private static func event(id: Int, completion: @escaping ((Record?) -> Void)) {
        firstly {
            CachingNetwork.getEvent(by: id)
        }.then { event -> Void in
            completion(event)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func events(ids: [Int], completion: @escaping (([Record]?) -> Void)) {
        let promises = ids.map { CachingNetwork.getTheme(by: $0) }

        firstly {
            when(fulfilled: promises)
        }.then { events -> Void in
            completion(events)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

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

    private static func events(for group: LetterGroup, completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getEvents(in: group)
        }.then { events -> Void in
            completion(events)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Organizations

    private static func organization(id: Int, completion: @escaping ((Record?) -> Void)) {
        firstly {
            CachingNetwork.getOrganization(by: id)
        }.then { organization -> Void in
            completion(organization)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func organizations(ids: [Int], completion: @escaping (([Record]?) -> Void)) {
        let promises = ids.map { CachingNetwork.getTheme(by: $0) }

        firstly {
            when(fulfilled: promises)
        }.then { organizations -> Void in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

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

    private static func organizations(for group: LetterGroup, completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getOrganizations(in: group)
        }.then { organizations -> Void in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Themes

    private static func theme(id: Int, completion: @escaping ((Record?) -> Void)) {
        firstly {
            CachingNetwork.getTheme(by: id)
        }.then { theme -> Void in
            completion(theme)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func themes(ids: [Int], completion: @escaping (([Record]?) -> Void)) {
        let promises = ids.map { CachingNetwork.getTheme(by: $0) }

        firstly {
            when(fulfilled: promises)
        }.then { themes -> Void in
            completion(themes)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

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

    private static func themes(for group: LetterGroup, completion: @escaping (([Record]?) -> Void)) {
        firstly {
            try CachingNetwork.getThemes(in: group)
        }.then { themes -> Void in
            completion(themes)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }


    // MARK: Collections

    private static func collection(id: Int, completion: @escaping ((Record?) -> Void)) {
        firstly {
            CachingNetwork.getCollection(by: id)
        }.then { collection -> Void in
            completion(collection)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

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
