//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


typealias AppState = (pair: Int?, group: Int?, type: ApplicationType)


/// Class used to determine which application's are paired with one another.
final class ConnectionManager {

    static let instance = ConnectionManager()

    /// The handler for map associated events
    var mapHandler: MapHandler?

    /// The state for each app indexed by it's appID
    private var stateForApp: [AppState]

    private struct Keys {
        static let id = "id"
        static let map = "map"
        static let group = "group"
        static let gesture = "gestureType"
        static let animated = "amimated"
    }


    // MARK: Init

    /// Use Singleton
    private init() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        let initialState = AppState(pair: nil, group: nil, type: .mapExplorer)
        self.stateForApp = Array(repeating: initialState, count: numberOfApps)
        subscribeToNotifications()
    }


    // MARK: API

    /// Returns the current pair for the given appID
    func pairForApp(id: Int) -> Int? {
        return stateForApp.at(index: id)?.pair
    }

    /// Returns the current group for the given appID
    func groupForApp(id: Int) -> Int? {
        return stateForApp.at(index: id)?.group
    }

    /// Returns the current application type for the given appID
    func typeForApp(id: Int) -> ApplicationType? {
        return stateForApp.at(index: id)?.type
    }

    /// Force the state of an application
    func set(state: AppState, forApp app: Int) {
        stateForApp[app] = state
    }


    // MARK: Notifications

    private func subscribeToNotifications() {
        for notification in ApplicationNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
        for notification in MapNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: SettingsNotification.split.name, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: SettingsNotification.merge.name, object: nil)
    }

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let id = info[Keys.id] as? Int else {
            return
        }

        let group = info[Keys.group] as? Int

        switch notification.name {
        case ApplicationNotification.launchMapExplorer.name:
            setAppType(.mapExplorer, from: id, group: group)
        case ApplicationNotification.launchTimeline.name:
            setAppType(.timeline, from: id, group: group)
        case ApplicationNotification.launchNodeNetwork.name:
            setAppType(.nodeNetwork, from: id, group: group)
        case MapNotification.position.name:
            if let mapJSON = info[Keys.map] as? JSON, let mapRect = MKMapRect(json: mapJSON), let group = group, let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture), let animated = info[Keys.animated] as? Bool {
                setAppState(from: id, group: group, for: .mapExplorer, momentum: state == .momentum)
                mapHandler?.handle(mapRect, fromID: id, fromGroup: group, animated: animated)
            }
        case MapNotification.unpair.name:
            unpair(from: id)
        case MapNotification.ungroup.name:
            if let group = group {
                ungroup(from: group, with: .mapExplorer)
            }
        case SettingsNotification.split.name:
            split(from: id, group: group)
        case SettingsNotification.merge.name:
            merge(from: id, group: group)
            syncApps(inGroup: group)
        default:
            return
        }
    }


    // MARK: Helpers

    private func setAppType(_ type: ApplicationType, from id: Int, group: Int?) {
        for (app, state) in stateForApp.enumerated() {
            // Check for current group
            if let appGroup = state.group, appGroup == group {
                // Check for current pair
                if let appPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(app - id) < abs(app - appPair) {
                        stateForApp[app] = AppState(pair: nil, group: id, type: type)
                    }
                } else {
                    stateForApp[app] = AppState(pair: nil, group: id, type: type)
                }
            } else if state.group == nil, state.type == type {
                stateForApp[app] = AppState(pair: nil, group: id, type: type)
            }
        }
    }

    /// Set all app states accordingly when a app sends its position
    private func setAppState(from id: Int, group: Int, for type: ApplicationType, momentum: Bool) {
        for (app, state) in stateForApp.enumerated() {
            // Only receive updates for apps of the same type
            if type != state.type {
                continue
            }

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
                        stateForApp[app] = AppState(pair: id, group: id, type: state.type)
                    }
                } else if !momentum {
                    stateForApp[app] = AppState(pair: id, group: id, type: state.type)
                }
            } else if state.group == nil {
                stateForApp[app] = AppState(pair: id, group: id, type: state.type)
            }
        }
    }

    /// Initiates a split between applications within the screen containing the given appID
    private func split(from id: Int, group: Int?) {
        let type = typeForApp(id: id)
        let neighborID = id % Configuration.appsPerScreen == 0 ? id + 1 : id - 1

        for (app, state) in stateForApp.enumerated() {
            // Only receive updates for apps of the same type
            if type != state.type {
                continue
            }

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
                    stateForApp[app] = AppState(pair: nil, group: closestApp, type: state.type)
                    if app == neighborID {
                        startTimerForApp(id: app, with: state.type)
                    }
                }
            } else if state.group == nil {
                // Group with the closest of the two apps being split
                stateForApp[app] = AppState(pair: nil, group: closestApp, type: state.type)
            }
        }
    }

    private func merge(from id: Int, group: Int?) {
        let type = typeForApp(id: id)
        let neighborID = id % Configuration.appsPerScreen == 0 ? id + 1 : id - 1

        for (app, state) in stateForApp.enumerated() {
            // Only receive updates for apps of the same type
            if type != state.type {
                continue
            }

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
                        stateForApp[app] = AppState(pair: nil, group: id, type: state.type)
                    }
                } else {
                    stateForApp[app] = AppState(pair: nil, group: id, type: state.type)
                }
            } else if state.group == nil {
                stateForApp[app] = AppState(pair: nil, group: id, type: state.type)
            } else if app == neighborID || state.group == neighborID {
                // Force the merge of neighbor app and everyone in it's group
                stateForApp[app] = AppState(pair: nil, group: id, type: state.type)
            }
        }
    }

    /// If paired to the given id, will unpair else ignore
    private func unpair(from id: Int) {
        for (app, state) in stateForApp.enumerated() {
            if let currentPair = state.pair, currentPair == id {
                stateForApp[app] = AppState(pair: nil, group: state.group, type: state.type)
            }
        }
    }

    /// Ungroup all apps from group with given id
    private func ungroup(from id: Int, with type: ApplicationType) {
        // Clear groups with given id
        for (app, state) in stateForApp.enumerated() {
            if let currentGroup = state.group, currentGroup == id {
                stateForApp[app] = AppState(pair: nil, group: nil, type: state.type)
            }
        }
        // Find the closest group for all ungrouped apps of the same type
        for (app, state) in stateForApp.enumerated() {
            if state.group == nil {
                let group = findGroupForApp(id: app, of: type)
                stateForApp[app] = AppState(pair: nil, group: group, type: state.type)
                syncApps(inGroup: group)
            }
        }
    }

    /// Find the closest group to a given app
    private func findGroupForApp(id: Int, of type: ApplicationType) -> Int? {
        let sortedAppStates = stateForApp.enumerated().sorted {
            if screen(of: $0.0) == screen(of: $1.0) {
                return abs(id - $0.0) < abs(id - $1.0)
            }
            return abs(screen(of: id) - screen(of: $0.0)) < abs(screen(of: id) - screen(of: $1.0))
        }

        let externalApps = sortedAppStates.dropFirst()
        let filteredApps = externalApps.filter { $0.1.type == type }
        return filteredApps.compactMap({ $0.1.group }).first
    }

    /// Send position notification that won't cause app's to pair but causes map to sync together
    private func syncApps(inGroup group: Int?) {
        guard let group = group, let type = typeForApp(id: group) else {
            return
        }

        switch type {
        case .mapExplorer:
            if let mapHandler = mapHandler, mapHandler.mapID == group {
                let mapRect = mapHandler.mapView.visibleMapRect
                mapHandler.send(mapRect, for: .momentum, forced: true)
            }
        default:
            return
        }
    }

    /// Starts the ungroup timer for the map handler associated with the given mapID
    private func startTimerForApp(id: Int, with type: ApplicationType) {
        switch type {
        case .mapExplorer:
            if let mapHandler = mapHandler, mapHandler.mapID == id {
                mapHandler.endUpdates()
            }
        default:
            return
        }
    }

    /// Returns the screen id of the given app id
    private func screen(of app: Int) -> Int {
        return (app / Configuration.appsPerScreen) + 1
    }
}
