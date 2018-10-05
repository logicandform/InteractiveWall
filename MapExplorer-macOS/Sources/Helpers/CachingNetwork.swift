//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Alamofire
import AlamofireImage
import PromiseKit
import MapKit


enum NetworkError: Error {
    case badRequest
    case unauthorized
    case notFound
    case serverError
    case badResponse
    case serializationError
}


final class CachingNetwork {

    private struct Endpoints {
        static let schools = Configuration.serverURL + "/schools/all/%d"
        static let events = Configuration.serverURL + "/events/all/%d"
        static let collections = Configuration.serverURL + "/collections/all/%d"
    }

    private struct Constants {
        static let batchSize = 20
    }


    // MARK: Generic

    /// Loads thumbnail for events using local or remote url depending on configuration settings
    static func getImage(for event: TimelineEvent, completion: @escaping (NSImage?) -> Void) {
        if Configuration.localMediaURLs {
            if let localURL = event.localThumbnail {
                let image = NSImage(contentsOf: localURL)
                completion(image)
            } else {
                completion(nil)
            }
        } else {
            if let url = event.thumbnail {
                Alamofire.request(url).responseImage { response in
                    completion(response.value)
                }
            } else {
                completion(nil)
            }
        }
    }


    // MARK: Schools

    static func getSchools(page: Int = 0, load: [School] = []) throws -> Promise<[School]> {
        let url = String(format: Endpoints.schools, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let schools = try? ResponseHandler.serializeSchools(from: json), !schools.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + schools
            return try getSchools(page: next, load: result)
        }
    }


    // MARK: Events

    static func getEvents(page: Int = 0, load: [Event] = []) throws -> Promise<[Event]> {
        let url = String(format: Endpoints.events, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let events = try? ResponseHandler.serializeEvents(from: json), !events.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + events
            return try getEvents(page: next, load: result)
        }
    }


    // MARK: Collections

    static func getCollections(page: Int = 0, load: [RecordCollection] = []) throws -> Promise<[RecordCollection]> {
        let url = String(format: Endpoints.collections, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let collections = try? ResponseHandler.serializeCollections(from: json), !collections.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let result = load + collections
            return try getCollections(page: next, load: result)
        }
    }

    static func getCollections(type: CollectionType, page: Int = 0, load: [RecordCollection] = []) throws -> Promise<[RecordCollection]> {
        let url = String(format: Endpoints.collections, page)

        return Alamofire.request(url).responseJSON().then { json in
            guard let collections = try? ResponseHandler.serializeCollections(from: json), !collections.isEmpty else {
                return Promise(value: load)
            }

            let next = page + Constants.batchSize
            let filtered = collections.filter { $0.collectionType == type }
            let result = load + filtered
            return try getCollections(page: next, load: result)
        }
    }
}
