//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit


final class DataLoader {

    // MARK: API

    func fetchRecords(of type: RecordType, then completion: @escaping ([RecordDisplayable]?) -> Void) {
        switch type {
        case .organization:
            getOrganizations(then: completion)
        case .event:
            getEvents(then: completion)
        case .artifact:
            getArtifacts(then: completion)
        case .school:
            getSchools(then: completion)
        case .theme:
            getThemes(then: completion)
        }
    }


    // MARK: Helpers

    private func getOrganizations(then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        firstly {
            try CachingNetwork.getOrganizations()
        }.then { organizations in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private func getEvents(then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        firstly {
            try CachingNetwork.getEvents()
        }.then { organizations in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private func getArtifacts(then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        firstly {
            try CachingNetwork.getArtifacts()
        }.then { organizations in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private func getSchools(then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        firstly {
            try CachingNetwork.getSchools()
        }.then { organizations in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private func getThemes(then completion: @escaping (([RecordDisplayable]?) -> Void)) {
        firstly {
            try CachingNetwork.getThemes()
        }.then { organizations in
            completion(organizations)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }
}
