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
    static let baseURL = "http://10.58.73.164:3000"

    private struct Endpoints {
        static let places = baseURL + "/places"
        static let placeByID = places + "/find/"
        static let organizations = baseURL + "/organizations"
        static let organizationByID = organizations + "/find/"
        static let events = baseURL + "/events"
        static let eventByID = events + "/find/"
        static let artifacts = baseURL + "/artifacts"
        static let artifactByID = artifacts + "/find/"
        static let schools = baseURL + "/schools"
        static let schoolByID = schools + "/find/"
        static let themes = baseURL + "/themes"
        static let themeByID = baseURL + "/find/"
    }

    private static let credentials: [String: String] = {
        let credentialData = "tim:ph@wRaBa63Dr".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }()


    // MARK: Places

    static func getPlaces() throws -> Promise<[Place]> {
        let url = Endpoints.places

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializePlaces(from: json)
        }
    }

    static func getPlace(by id: Int) -> Promise<Place> {
        let url = Endpoints.placeByID + id.description

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializePlace(from: json)
        }
    }


    // MARK: Organizations

    static func getOrganizations() throws -> Promise<[Organization]> {
        let url = Endpoints.organizations

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeOrganizations(from: json)
        }
    }

    static func getOrganization(by id: Int) -> Promise<Organization> {
        let url = Endpoints.organizationByID + id.description

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeOrganization(from: json)
        }
    }


    // MARK: Events

    static func getEvents() throws -> Promise<[Event]> {
        let url = Endpoints.events

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeEvents(from: json)
        }
    }

    static func getEvent(by id: Int) -> Promise<Event> {
        let url = Endpoints.eventByID + id.description

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeEvent(from: json)
        }
    }


    // MARK: Artifacts

    static func getArtifacts() throws -> Promise<[Artifact]> {
        let url = Endpoints.artifacts

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeArtifacts(from: json)
        }
    }

    static func getArtifact(by id: Int) -> Promise<Artifact> {
        let url = Endpoints.artifactByID + id.description

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeArtifact(from: json)
        }
    }


    // MARK: Schools

    static func getSchools() throws -> Promise<[School]> {
        let url = Endpoints.schools

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeSchools(from: json)
        }
    }

    static func getSchool(by id: Int) -> Promise<School> {
        let url = Endpoints.schoolByID + id.description

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeSchool(from: json)
        }
    }


    // MARK: Themes

    static func getThemes() throws -> Promise<[Theme]> {
        let url = Endpoints.themes

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeThemes(from: json)
        }
    }

    static func getTheme(by id: Int) -> Promise<Theme> {
        let url = Endpoints.themeByID + id.description

        return Alamofire.request(url).responseJSON().then { json in
            try ResponseHandler.serializeTheme(from: json)
        }
    }
}
