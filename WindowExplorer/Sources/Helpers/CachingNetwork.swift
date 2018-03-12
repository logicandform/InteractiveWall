//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Alamofire
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
        static let baseURL = "http://192.168.1.93:3100"
        static let placesURL = baseURL + "/places"
        static let organizationsURL = baseURL + "/organizations"
        static let eventsURL = baseURL + "/events"
        static let artifactsURL = baseURL + "/artifacts"
        static let schoolsURL = baseURL + "/schools"
    }

    private static let credentials: [String: String] = {
        let credentialData = "tim:ph@wRaBa63Dr".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }()


    // MARK: Places

    static func getPlaces() throws -> Promise<[Place]> {
        let url = Endpoints.placesURL

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializePlaces(from: json)
        }
    }

    static func getPlace(by id: Int) -> Promise<Place> {
        let url = Endpoints.placesURL + "/" + id.description

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializePlace(from: json)
        }
    }


    // MARK: Organizations

    static func getOrganizations() throws -> Promise<[Organization]> {
        let url = Endpoints.organizationsURL

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeOrganizations(from: json)
        }
    }

    static func getOrganization(by id: Int) -> Promise<Organization> {
        let url = Endpoints.organizationsURL + "/" + id.description

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeOrganization(from: json)
        }
    }


    // MARK: Events

    static func getEvents() throws -> Promise<[Event]> {
        let url = Endpoints.eventsURL

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeEvents(from: json)
        }
    }

    static func getEvent(by id: Int) -> Promise<Event> {
        let url = Endpoints.eventsURL + "/" + id.description

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeEvent(from: json)
        }
    }


    // MARK: Artifacts

    static func getArtifacts() throws -> Promise<[Artifact]> {
        let url = Endpoints.artifactsURL

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeArtifacts(from: json)
        }
    }

    static func getArtifact(by id: Int) -> Promise<Artifact> {
        let url = Endpoints.artifactsURL + "/" + id.description

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeArtifact(from: json)
        }
    }


    // MARK: Schools

    static func getSchools() throws -> Promise<[School]> {
        let url = Endpoints.schoolsURL

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeSchools(from: json)
        }
    }

    static func getSchool(by id: Int) -> Promise<School> {
        let url = Endpoints.schoolsURL + "/" + id.description

        return Alamofire.request(url, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializeSchool(from: json)
        }
    }
}
