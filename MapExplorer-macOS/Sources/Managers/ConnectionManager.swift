//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


typealias AppState = (pair: Int?, group: Int?)


/// Class used to determine which application's are paired with one another.
final class ConnectionManager {
    static let instance = ConnectionManager()

    /// The handler for map associated events
    weak var mapHandler: MapHandler?

    /// The handler for timeline associated events
    weak var timelineHandler: TimelineHandler?

    weak var timelineViewController: TimelineViewController?

    /// The current application type for an appID
    private var typeForApp = [ApplicationType]()

    /// The state for each map indexed by it's appID
    private var stateForMap: [AppState]

    /// The state for each timeline indexed by it's appID
    private var stateForTimeline: [AppState]

    private struct Keys {
        static let id = "id"
        static let map = "map"
        static let day = "day"
        static let month = "month"
        static let year = "year"
        static let type = "type"
        static let group = "group"
        static let oldType = "oldType"
        static let animated = "amimated"
        static let gesture = "gestureType"
    }


    // MARK: Init

    /// Use Singleton
    private init() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        let initialState = AppState(pair: nil, group: nil)
        self.stateForMap = Array(repeating: initialState, count: numberOfApps)
        self.stateForTimeline = Array(repeating: initialState, count: numberOfApps)
        self.typeForApp = Array(repeating: .mapExplorer, count: numberOfApps)
    }


    // MARK: API

    /// Returns the current pair for the given appID
    func pairForApp(id: Int, type: ApplicationType) -> Int? {
        switch type {
        case .mapExplorer:
            return stateForMap.at(index: id)?.pair
        case .timeline:
            return stateForTimeline.at(index: id)?.pair
        case .nodeNetwork:
            return nil
        }
    }

    /// Returns the current group for the given appID
    func groupForApp(id: Int, type: ApplicationType) -> Int? {
        switch type {
        case .mapExplorer:
            return stateForMap.at(index: id)?.group
        case .timeline:
            return stateForTimeline.at(index: id)?.group
        case .nodeNetwork:
            return nil
        }
    }

    /// Returns the current application type for the given appID
    func typeForApp(id: Int) -> ApplicationType? {
        return typeForApp[id]
    }

    /// Set the state of an application
    func set(_ state: AppState, for type: ApplicationType, id: Int) {
        switch type {
        case .mapExplorer:
            stateForMap[id] = state
        case .timeline:
            stateForTimeline[id] = state
        case .nodeNetwork:
            return
        }
    }

    func registerForNotifications() {
        for notification in MapNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
        for notification in TimelineNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
        for notification in SettingsNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }


    // MARK: Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let id = info[Keys.id] as? Int else {
            return
        }

        let group = info[Keys.group] as? Int

        switch notification.name {
        case MapNotification.mapRect.name:
            if let mapJSON = info[Keys.map] as? JSON, let mapRect = MKMapRect(json: mapJSON), let group = group, let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture), let animated = info[Keys.animated] as? Bool {
                setAppState(from: id, group: group, for: .mapExplorer, momentum: state == .momentum)
                mapHandler?.handle(mapRect, fromID: id, fromGroup: group, animated: animated)
            }
        case TimelineNotification.rect.name:
            if let day = info[Keys.day] as? CGFloat, let month = info[Keys.month] as? Int, let year = info[Keys.year] as? Int, let group = group, let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture), let animated = info[Keys.animated] as? Bool {
                setAppState(from: id, group: group, for: .timeline, momentum: state == .momentum)
                timelineHandler?.handle(date: (day, month, year), fromID: id, fromGroup: group, animated: animated)
            }
        case SettingsNotification.transition.name:
            if let newTypeString = info[Keys.type] as? String, let newType = ApplicationType(rawValue: newTypeString), let oldTypeString = info[Keys.oldType] as? String, let oldType = ApplicationType(rawValue: oldTypeString) {
                transition(from: oldType, to: newType, id: id, group: group)
            }
        case SettingsNotification.unpair.name:
            if let typeString = info[Keys.type] as? String, let type = ApplicationType(rawValue: typeString) {
                unpair(from: id, for: type)
            }
        case SettingsNotification.ungroup.name:
            if let group = group, let typeString = info[Keys.type] as? String, let type = ApplicationType(rawValue: typeString) {
                ungroup(from: group, for: type)
            }
        case SettingsNotification.split.name:
            if let typeString = info[Keys.type] as? String, let type = ApplicationType(rawValue: typeString) {
                split(from: id, group: group, of: type)
            }
        case SettingsNotification.merge.name:
            if let typeString = info[Keys.type] as? String, let type = ApplicationType(rawValue: typeString) {
                merge(from: id, group: group, of: type)
            }
            syncApps(inGroup: group)
        case SettingsNotification.reset.name:
            mapHandler?.reset(animated: true)
            timelineHandler?.reset(animated: true)
        default:
            return
        }
    }


    // MARK: Helpers

    private func states(for type: ApplicationType) -> [AppState] {
        switch type {
        case .mapExplorer:
            return stateForMap
        case .timeline:
            return stateForTimeline
        case .nodeNetwork:
            return []
        }
    }

    private func transition(from oldType: ApplicationType, to newType: ApplicationType, id: Int, group: Int?) {
        let appStates = states(for: oldType).enumerated()

        for (app, state) in appStates {
            if oldType != typeForApp(id: app) {
                continue
            }

            // Check for current group
            if state.group == group {
                // Check for current pair
                if let appPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(app - id) < abs(app - appPair) || appPair == id {
                        typeForApp[app] = newType
                        transitionController(id: app, to: newType)
                    }
                } else {
                    typeForApp[app] = newType
                    transitionController(id: app, to: newType)
                }
            }
        }
    }

    /// Set all app states accordingly when a app sends its position
    private func setAppState(from id: Int, group: Int, for type: ApplicationType, momentum: Bool) {
        let newState = AppState(pair: id, group: id)
        let appStates = states(for: type).enumerated()

        for (app, state) in appStates {
            // Check for current group
            if let appGroup = state.group, appGroup == group {
                // Once paired with own screen, don't group to other screens
                if screen(of: appGroup) == screen(of: app) && screen(of: app) != screen(of: id) {
                    continue
                }
                // Only listen to the closest screen once paired
                if abs(screen(of: app) - screen(of: id)) >= abs(screen(of: app) - screen(of: appGroup)), screen(of: id) != screen(of: group) {
                    continue
                }
                // Check for current pair
                if let appPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(app - id) < abs(app - appPair) {
                        set(newState, for: type, id: app)
                    }
                } else if !momentum {
                    set(newState, for: type, id: app)
                }
            } else if state.group == nil {
                set(newState, for: type, id: app)
            }
        }
    }

    /// Initiates a split between applications within the screen containing the given appID
    private func split(from id: Int, group: Int?, of type: ApplicationType) {
        let neighborID = id % Configuration.appsPerScreen == 0 ? id + 1 : id - 1
        let appStates = states(for: type).enumerated()

        for (app, state) in appStates {
            // Calculate closest appID of the screen being split
            let closestApp = abs(app - id) < abs(app - neighborID) ? id : neighborID

            // Check for current group
            if let appGroup = state.group, appGroup == group {
                // Once paired with own screen, don't group to other screens
                if screen(of: appGroup) == screen(of: app) && screen(of: app) != screen(of: id) {
                    continue
                }
                // Only listen to the closest screen once paired
                if let group = group, abs(screen(of: app) - screen(of: id)) >= abs(screen(of: app) - screen(of: appGroup)), screen(of: id) != screen(of: group) {
                    continue
                }
                // If app is farther or equal to the group then the app splitting, join the closest appID
                if abs(appGroup - app) >= abs(appGroup - id) {
                    set(AppState(pair: nil, group: closestApp), for: type, id: app)
                    if app == neighborID {
                        resetTimerForApp(id: app, with: type)
                    }
                }
            } else if state.group == nil {
                // Group with the closest of the two apps being split
                set(AppState(pair: nil, group: closestApp), for: type, id: app)
            }
        }
    }

    private func merge(from id: Int, group: Int?, of type: ApplicationType) {
        let neighborID = id % Configuration.appsPerScreen == 0 ? id + 1 : id - 1
        let newState = AppState(pair: nil, group: id)
        let appStates = states(for: type).enumerated()

        for (app, state) in appStates {
            // Check for current group
            if let appGroup = state.group, appGroup == group {
                // Once paired with own screen, don't group to other screens
                if screen(of: appGroup) == screen(of: app) && screen(of: app) != screen(of: id) {
                    continue
                }
                // Only listen to the closest screen once paired
                if let group = group, abs(screen(of: app) - screen(of: id)) >= abs(screen(of: app) - screen(of: appGroup)), screen(of: id) != screen(of: group) {
                    continue
                }
                // Check for current pair
                if let appPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(app - id) < abs(app - appPair) {
                        set(newState, for: type, id: app)
                    }
                } else {
                    set(newState, for: type, id: app)
                }
            } else if state.group == nil {
                set(newState, for: type, id: app)
            } else if app == neighborID || state.group == neighborID {
                // Force the merge of neighbor app and everyone in it's group
                set(newState, for: type, id: app)
            }
        }
    }

    /// If paired to the given id, will unpair else ignore
    private func unpair(from id: Int, for type: ApplicationType) {
        let appStates = states(for: type).enumerated()

        for (app, state) in appStates {
            if let currentPair = state.pair, currentPair == id {
                set(AppState(pair: nil, group: state.group), for: type, id: app)
            }
        }
    }

    /// Ungroup all apps from group with given id
    private func ungroup(from id: Int, for type: ApplicationType) {
        var appStates = states(for: type).enumerated()

        // Clear groups with given id
        for (app, state) in appStates {
            if let currentGroup = state.group, currentGroup == id {
                set(AppState(pair: nil, group: nil), for: type, id: app)
            }
        }

        // Find the closest group for all ungrouped apps of the same type
        appStates = states(for: type).enumerated()
        for (app, state) in appStates {
            if state.group == nil {
                let group = findGroupForApp(id: app, of: type)
                set(AppState(pair: nil, group: group), for: type, id: app)
                syncApps(inGroup: group)
            }
        }
    }

    /// Find the closest group to a given app
    private func findGroupForApp(id: Int, of type: ApplicationType) -> Int? {
        let appStates = states(for: type).enumerated()
        let sortedAppStates = appStates.sorted {
            if screen(of: $0.0) == screen(of: $1.0) {
                return abs(id - $0.0) < abs(id - $1.0)
            }
            return abs(screen(of: id) - screen(of: $0.0)) < abs(screen(of: id) - screen(of: $1.0))
        }

        let externalApps = sortedAppStates.dropFirst()
        return externalApps.compactMap({ $0.1.group }).first
    }

    /// From the app matching the groupID, send position notification that won't cause app's to pair but causes map to sync together
    private func syncApps(inGroup group: Int?) {
        guard let group = group, let type = typeForApp(id: group), appID == group else {
            return
        }

        switch type {
        case .mapExplorer:
            if let mapHandler = mapHandler {
                let mapRect = mapHandler.mapView.visibleMapRect
                mapHandler.send(mapRect, for: .momentum, forced: true)
            }
        case .timeline:
            if let timelineHandler = timelineHandler, let timelineViewController = timelineViewController {
                let date = timelineViewController.currentDate
                timelineHandler.send(date: date, for: .momentum, forced: true)
            }
        default:
            return
        }
    }

    /// Starts the ungroup timer for the map handler associated with the given mapID
    private func resetTimerForApp(id: Int?, with type: ApplicationType) {
        guard let id = id, appID == id else {
            return
        }

        switch type {
        case .mapExplorer:
            mapHandler?.endUpdates()
        case .timeline:
            timelineHandler?.endUpdates()
        default:
            return
        }
    }

    /// Returns the screen id of the given app id
    private func screen(of app: Int) -> Int {
        return (app / Configuration.appsPerScreen) + 1
    }

    private func transitionController(id: Int, to type: ApplicationType) {
        if id == appID {
            timelineViewController?.fade(out: type != .timeline)
        }
    }
}
