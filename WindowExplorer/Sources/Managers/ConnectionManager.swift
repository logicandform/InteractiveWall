//  Copyright © 2018 JABT. All rights reserved.

import Foundation


typealias AppState = (pair: Int?, group: Int?)


/// Class used to determine which application's are paired with one another.
final class ConnectionManager {
    static let instance = ConnectionManager()

    /// The current application type for an appID
    private var typeForApp = [ApplicationType]()

    /// The state for each map indexed by it's appID
    private var stateForMap: [AppState]

    /// The state for each node indexed by it's appID
    private var stateForNode: [AppState]

    /// The state for each timeline indexed by it's appID
    private var stateForTimeline: [AppState]

    /// A timer used to reset the entire installation when no activity has been detected
    private weak var resetTimer: Foundation.Timer?

    private struct Keys {
        static let id = "id"
        static let map = "map"
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
        self.stateForNode = Array(repeating: initialState, count: numberOfApps)
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
    func groupForApp(id: Int) -> Int? {
        switch typeForApp(id: id) {
        case .mapExplorer:
            return stateForMap.at(index: id)?.group
        case .timeline:
            return stateForTimeline.at(index: id)?.group
        case .nodeNetwork:
            return nil
        }
    }

    /// Returns the current application type for the given appID
    func typeForApp(id: Int) -> ApplicationType {
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

    func states(for type: ApplicationType) -> [AppState] {
        switch type {
        case .mapExplorer:
            return stateForMap
        case .timeline:
            return stateForTimeline
        case .nodeNetwork:
            return stateForNode
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
            if let group = group, let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture) {
                setAppState(from: id, group: group, for: .mapExplorer, gestureState: state)
            }
        case TimelineNotification.rect.name:
            if let group = group, let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture) {
                setAppState(from: id, group: group, for: .timeline, gestureState: state)
            }
        case SettingsNotification.transition.name:
            if let newTypeString = info[Keys.type] as? String, let newType = ApplicationType(rawValue: newTypeString), let oldTypeString = info[Keys.oldType] as? String, let oldType = ApplicationType(rawValue: oldTypeString) {
                transition(from: oldType, to: newType, id: id, group: group)
            }
        case SettingsNotification.unpair.name:
            if let typeString = info[Keys.type] as? String, let type = ApplicationType(rawValue: typeString) {
                unpair(from: id, for: type)
            }
            resetTimer?.invalidate()
        case SettingsNotification.ungroup.name:
            beginResetTimer()
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
                syncApps(group: group, type: type)
            }
        case SettingsNotification.reset.name:
            reset()
        default:
            return
        }
    }


    // MARK: Helpers

    private func transition(from oldType: ApplicationType, to newType: ApplicationType, id: Int, group: Int?) {
        let newState = AppState(pair: nil, group: id)
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
                        set(newState, for: newType, id: app)
                        updateMenu(id: app, to: newType)
                        syncApps(group: group, type: newType)
                    }
                } else {
                    typeForApp[app] = newType
                    set(newState, for: newType, id: app)
                    updateMenu(id: app, to: newType)
                    syncApps(group: group, type: newType)
                }
            }
        }
        updateViews()
    }

    private func reset() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        let initialState = AppState(pair: nil, group: nil)
        stateForMap = Array(repeating: initialState, count: numberOfApps)
        stateForTimeline = Array(repeating: initialState, count: numberOfApps)
        typeForApp = Array(repeating: .mapExplorer, count: numberOfApps)
        for app in (0 ..< numberOfApps) {
            updateMenu(id: app, to: .mapExplorer)
        }
        updateViews()
    }

    /// Set all app states accordingly when a app sends its position
    private func setAppState(from id: Int, group: Int, for type: ApplicationType, gestureState: GestureState) {
        let pair = gestureState.interruptible ? nil : id
        let newState = AppState(pair: pair, group: id)
        let appStates = states(for: type).enumerated()

        for (app, state) in appStates {
            // Check for current group
            if let appGroup = state.group, appGroup == group {
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
                } else {
                    set(newState, for: type, id: app)
                }
            } else if state.group == nil {
                set(newState, for: type, id: app)
            }
        }
        updateViews()
    }

    /// Initiates a split between applications within the screen containing the given appID
    private func split(from id: Int, group: Int?, of type: ApplicationType) {
        let neighborID = id.isEven ? id + 1 : id - 1
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
                }
            } else if state.group == nil {
                // Group with the closest of the two apps being split
                set(AppState(pair: nil, group: closestApp), for: type, id: app)
            }
        }
        updateViews()
    }

    private func merge(from id: Int, group: Int?, of type: ApplicationType) {
        let neighborID = id.isEven ? id + 1 : id - 1
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
        updateViews()
    }

    /// If paired to the given id, will unpair else ignore
    private func unpair(from id: Int, for type: ApplicationType) {
        let appStates = states(for: type).enumerated()

        for (app, state) in appStates {
            if let currentPair = state.pair, currentPair == id {
                set(AppState(pair: nil, group: state.group), for: type, id: app)
            }
        }
        updateViews()
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
                syncApps(group: group, type: type)
            }
        }
        updateViews()
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

    /// Returns the screen id of the given app id
    private func screen(of id: Int) -> Int {
        return (id / Configuration.appsPerScreen) + 1
    }

    /// Shows / Hides borders between applications and notifies menu controllers of updates
    private func updateViews() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens

        // Update the split button and lock view in each menu controller
        for app in (0 ..< numberOfApps) {
            let type = typeForApp(id: app)
            let statesForType = states(for: type)
            let menu = MenuManager.instance.menuForApp(id: app)
            let border = MenuManager.instance.borderForApp(id: app)
            let neighborID = app.isEven ? app + 1 : app - 1
            let neighborPair = pairForApp(id: neighborID, type: type)
            let differentTypes = type != typeForApp(id: neighborID)
            let split = differentTypes || statesForType[app].group != statesForType[neighborID].group
            let mergeLocked = differentTypes || split && neighborPair == neighborID
            menu?.set(.split, selected: split)
            menu?.toggleMergeLock(on: mergeLocked)
            border?.set(visible: split)
        }
    }

    /// Sets the menu for the application id to the given type
    private func updateMenu(id: Int, to type: ApplicationType) {
        if let menuButtonType = MenuButtonType.from(type) {
            let menu = MenuManager.instance.menuForApp(id: id)
            menu?.set(menuButtonType, selected: true)
        }
    }

    private func syncApps(group: Int?, type: ApplicationType) {
        if let group = group {
            SettingsManager.instance.syncApps(group: group, type: type)
        }
    }

    private func beginResetTimer() {
        resetTimer?.invalidate()
        resetTimer = Timer.scheduledTimer(withTimeInterval: Configuration.resetTimeoutDuration, repeats: false) { [weak self] _ in
            self?.resetTimerFired()
        }
    }

    private func resetTimerFired() {
        let info: JSON = [Keys.id: 0]
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.reset.name, object: nil, userInfo: info, deliverImmediately: true)
    }
}
