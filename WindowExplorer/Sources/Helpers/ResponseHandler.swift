//  Copyright © 2018 JABT. All rights reserved.

import Foundation

final class ResponseHandler {


    // MARK: Places

    static func serializePlaces(from json: Any) throws -> [Place] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { Place(json: $0) }
    }

    static func serializePlace(from json: Any) throws -> Place {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let place = Place(json: json) else {
            throw NetworkError.serializationError
        }

        return place
    }


    // MARK: Events

    static func serializeEvents(from json: Any) throws -> [Event] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { Event(json: $0) }
    }

    static func serializeEvent(from json: Any) throws -> Event {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let event = Event(json: json) else {
            throw NetworkError.serializationError
        }

        return event
    }


    // MARK: Artifacts

    static func serializeArtifacts(from json: Any) throws -> [Artifact] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { Artifact(json: $0) }
    }

    static func serializeArtifact(from json: Any) throws -> Artifact {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let artifact = Artifact(json: json) else {
            throw NetworkError.serializationError
        }

        return artifact
    }


    // MARK: Organizations

    static func serializeOrganizations(from json: Any) throws -> [Organization] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { Organization(json: $0) }
    }

    static func serializeOrganization(from json: Any) throws -> Organization {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let organization = Organization(json: json) else {
            throw NetworkError.serializationError
        }

        return organization
    }


    // MARK: Schools

    static func serializeSchools(from json: Any) throws -> [School] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { School(json: $0) }
    }

    static func serializeSchool(from json: Any) throws -> School {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let school = School(json: json) else {
            throw NetworkError.serializationError
        }

        return school
    }


    // MARK: Themes

    static func serializeThemes(from json: Any) throws -> [Theme] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.flatMap { Theme(json: $0) }
    }

    static func serializeTheme(from json: Any) throws -> Theme {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let theme = Theme(json: json) else {
            throw NetworkError.serializationError
        }

        return theme
    }
}
