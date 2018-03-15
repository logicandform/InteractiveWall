//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import PromiseKit

final class RecordFactory {

    static func record(for type: RecordType, id: Int, completion: @escaping ((RecordDisplayable?) -> Void)) {
        switch type {
        case .artifact:
            artifact(id: id, completion: completion)
        case .school:
            school(id: id, completion: completion)
        case .event:
            event(id: id, completion: completion)
        case .organization:
            organization(id: id, completion: completion)
        }
    }


    // MARK: Helpers

    private static func artifact(id: Int, completion: @escaping ((RecordDisplayable?) -> Void)) {
        firstly {
            CachingNetwork.getArtifact(by: id)
        }.then { artifact -> Void in
            completion(artifact)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func school(id: Int, completion: @escaping ((RecordDisplayable?) -> Void)) {
        firstly {
            CachingNetwork.getSchool(by: id)
        }.then { school -> Void in
            completion(school)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func event(id: Int, completion: @escaping ((RecordDisplayable?) -> Void)) {
        firstly {
            CachingNetwork.getEvent(by: id)
        }.then { event -> Void in
            completion(event)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }

    private static func organization(id: Int, completion: @escaping ((RecordDisplayable?) -> Void)) {
        firstly {
            CachingNetwork.getOrganization(by: id)
        }.then { organization -> Void in
            completion(organization)
        }.catch { error in
            print(error)
            completion(nil)
        }
    }
}
