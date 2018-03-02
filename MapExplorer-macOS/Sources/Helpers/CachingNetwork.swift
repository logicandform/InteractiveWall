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
}

final class CachingNetwork {

    private struct Endpoints {
        static let baseURL = "http://34.216.252.157:3000"
        static let createAll = baseURL + "/createAll"
        static let resetAll = baseURL + "/resetAll"
        static let updateAll = baseURL + "/updateAll"

        static let eventsURL = baseURL + "/events"
        static let createEvents = eventsURL + "/create"
        static let updateEvents = eventsURL + "/update"
        static let resetEvents = eventsURL + "/reset"
        static let createEventAssociations = eventsURL + "/createAssociations"
        static let downloadEventMedia = eventsURL + "/downloadMedia"

        static let objectsURL = baseURL + "/objects"
        static let createObjects = objectsURL + "/create"
        static let updateObjects = objectsURL + "/update"
        static let resetObjects = objectsURL + "/reset"
        static let createObjectAssociations = objectsURL + "/createAssociations"
        static let downloadObjectMedia = objectsURL + "/downloadMedia"

        static let organizationsURL = baseURL + "/organizations"
        static let createOrganizations = organizationsURL + "/create"
        static let updateOrganizations = organizationsURL + "/update"
        static let resetOrganizations = organizationsURL + "/reset"
        static let createOrganizationAssociations = organizationsURL + "/createAssociations"
        static let downloadOrganizationMedia = organizationsURL + "/downloadMedia"

        static let placesURL = baseURL + "/places"
        static let createPlaces = placesURL + "/create"
        static let updatePlaces = placesURL + "/update"
        static let resetPlaces = placesURL + "/reset"
        static let createPlacesAssociations = placesURL + "/createAssociations"
        static let downloadPlacesMedia = placesURL + "/downloadMedia"

        static let schoolsURL = baseURL + "/schools"
        static let createSchools = schoolsURL + "/create"
        static let updateSchools = schoolsURL + "/update"
        static let resetSchools = schoolsURL + "/reset"
        static let createSchoolAssociations = schoolsURL + "/createAssociations"
        static let downloadSchoolsMedia = schoolsURL + "/downloadMedia"

        static let themesURL = baseURL + "/themes"
        static let createThemes = themesURL + "/create"
        static let updateThemes = themesURL + "/update"
        static let resetThemes = themesURL + "/reset"
        static let downloadThemesMedia = themesURL + "/downloadMedia"
    }

    private static let credentials: [String: String] = {
        let credentialData = "Tim:ph@wRaBa63Dr".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }()


    // MARK: API

    static func getPlaces() throws -> Promise<[Place]> {
        return Alamofire.request(Endpoints.placesURL, headers: credentials).responseJSON().then { json in
            try ResponseHandler.serializePlaces(from: json)
        }
    }

    static func getEventByID(id: Int) throws -> Promise<[Event]> {
        return Alamofire.request(Endpoints.objectsURL, headers: credentials).responseJSON().then { json in
            try ResponseHandler.findObject(from: json)
        }
    }

}
