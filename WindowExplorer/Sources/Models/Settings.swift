//  Copyright © 2018 JABT. All rights reserved.

import Foundation


struct Settings {

    var showLabels = Defaults.labels
    var showMiniMap = Defaults.miniMap
    var displayEvents = Defaults.events
    var displayArtifacts = Defaults.artifacts
    var displaySchools = Defaults.schools
    var displayOrganizations = Defaults.organizations

    private struct Defaults {
        static let labels = true
        static let miniMap = false
        static let events = true
        static let artifacts = true
        static let schools = true
        static let organizations = true
    }

    private struct Keys {
        static let labels = "labels"
        static let miniMap = "miniMap"
        static let events = "events"
        static let artifacts = "artifacts"
        static let schools = "schools"
        static let organizations = "organizations"
    }


    // MARK: Init

    init() { }

    init?(json: JSON) {
        guard let showLabels = json[Keys.labels] as? Bool,
            let showMiniMap = json[Keys.miniMap] as? Bool,
            let displayEvents = json[Keys.events] as? Bool,
            let displayArtifacts = json[Keys.artifacts] as? Bool,
            let displaySchools = json[Keys.schools] as? Bool,
            let displayOrganizations = json[Keys.organizations] as? Bool else {
                return nil
        }

        self.showLabels = showLabels
        self.showMiniMap = showMiniMap
        self.displayEvents = displayEvents
        self.displayArtifacts = displayArtifacts
        self.displaySchools = displaySchools
        self.displayOrganizations = displayOrganizations
    }


    // MARK: API

    mutating func clone(_ settings: Settings) {
        showLabels = settings.showLabels
        showMiniMap = settings.showMiniMap
        displayEvents = settings.displayEvents
        displayArtifacts = settings.displayArtifacts
        displaySchools = settings.displaySchools
        displayOrganizations = settings.displayOrganizations
    }

    mutating func reset() {
        showLabels = Defaults.labels
        showMiniMap = Defaults.miniMap
        displayEvents = Defaults.events
        displayArtifacts = Defaults.artifacts
        displaySchools = Defaults.schools
        displayOrganizations = Defaults.organizations
    }

    mutating func set(_ type: RecordType, on: Bool) {
        switch type {
        case .event:
            displayEvents = on
        case .artifact:
            displayArtifacts = on
        case .school:
            displaySchools = on
        case .organization:
            displayOrganizations = on
        case .theme, .collection:
            return
        }
    }

    func displaying(_ type: RecordType) -> Bool {
        switch type {
        case .event:
            return displayEvents
        case .artifact:
            return displayArtifacts
        case .school:
            return displaySchools
        case .organization:
            return displayOrganizations
        case .theme, .collection:
            return false
        }
    }


    // MARK: JSON

    func toJSON() -> JSON {
        return [Keys.labels: showLabels,
                Keys.miniMap: showMiniMap,
                Keys.events: displayEvents,
                Keys.artifacts: displayArtifacts,
                Keys.schools: displaySchools,
                Keys.organizations: displayOrganizations]
    }
}
