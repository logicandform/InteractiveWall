//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class ResponseHandler {


    // MARK: Generic

    static func serializeCount(from json: Any) throws -> Int {
        guard let count = json as? Int else {
            throw NetworkError.badResponse
        }

        return count
    }


    // MARK: Organizations

    static func serializeOrganizations(from json: Any) throws -> [Organization] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { Organization(json: $0) }
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


    // MARK: Events

    static func serializeEvents(from json: Any) throws -> [Event] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { Event(json: $0) }
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

        return json.compactMap { Artifact(json: $0) }
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


    // MARK: Schools

    static func serializeSchools(from json: Any) throws -> [School] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { School(json: $0) }
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

        return json.compactMap { Theme(json: $0) }
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


    // MARK: Collections

    static func serializeCollections(from json: Any) throws -> [RecordCollection] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { RecordCollection(json: $0) }
    }

    static func serializeCollection(from json: Any) throws -> RecordCollection {
        guard let json = json as? JSON else {
            throw NetworkError.badResponse
        }

        if json.isEmpty {
            throw NetworkError.notFound
        }

        guard let collection = RecordCollection(json: json) else {
            throw NetworkError.serializationError
        }

        return collection
    }
}
