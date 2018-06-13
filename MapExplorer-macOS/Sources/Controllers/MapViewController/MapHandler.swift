//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


typealias MapState = (pair: Int?, group: Int?)

private enum UserActivity {
    case idle
    case active
}


class MapHandler {

    let mapView: MKMapView
    let mapID: Int
    let mapViewController: MapViewController

    var border: NSView?

    /// The state for a map indexed by it's mapID
    private var stateForMap: [MapState]
    private var activityState = UserActivity.idle
    private weak var ungroupTimer: Foundation.Timer?
    private weak var resetTimer: Foundation.Timer?

    private var mapState: MapState {
        return stateForMap[mapID]
    }

    struct MapConstants {
        static let canadaRect = MKMapRect(origin: MKMapPoint(x: 23000000, y: 70000000), size: MKMapSize(width: 80000000, height: 0))
    }

    private struct Constants {
        static let masterID = 0
        static let ungroupTimeoutPeriod: TimeInterval = 10
        static let resetTimeoutPeriod: TimeInterval = 180
        static let verticalPanLimit: Double = 100000000
        static let verticalVisibleMapRatio = 0.25
    }

    private struct Keys {
        static let id = "id"
        static let map = "map"
        static let group = "group"
        static let gesture = "gestureType"
        static let animated = "amimated"
        static let toggleOn = "toggleOn"
        static let switchType = "switchType"
    }


    // MARK: Init

    init(mapView: MKMapView, id: Int, mapViewController: MapViewController) {
        self.mapView = mapView
        self.mapID = id
        self.mapViewController = mapViewController
        let numberOfMaps = Configuration.mapsPerScreen * Configuration.numberOfScreens
        let initialState = MapState(pair: nil, group: nil)
        self.stateForMap = Array(repeating: initialState, count: numberOfMaps)
        subscribeToNotifications()
    }


    // MARK: API

    func send(_ mapRect: MKMapRect, for gestureState: GestureState = .recognized, animated: Bool = false) {
        // If sending from momentum but another map has interrupted, ignore
        if gestureState == .momentum && mapState.pair != nil {
            return
        }

        let group = mapState.group ?? mapID
        let info: JSON = [Keys.id: mapID, Keys.group: group, Keys.map: mapRect.toJSON(), Keys.gesture: gestureState.rawValue, Keys.animated: animated]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.position.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endActivity() {
        stateForMap[mapID] = MapState(pair: nil, group: mapState.group)
        let info: JSON = [Keys.id: mapID]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        activityState = .idle
        beginUngroupTimer()
    }

    func reset() {
        let canadaRect = MapConstants.canadaRect
        if Configuration.mapsPerScreen == 1 {
            mapView.setVisibleMapRect(MKMapRect(origin: canadaRect.origin, size: canadaRect.size), animated: true)
        } else {
            let newWidth = canadaRect.size.width / (Double(Configuration.mapsPerScreen) - 1.0)
            let newXOrigin = ((Double(mapID).truncatingRemainder(dividingBy: Double(Configuration.mapsPerScreen)) * newWidth) - (newWidth / 2)) + canadaRect.origin.x
            let mapRect = MKMapRect(origin: MKMapPoint(x: newXOrigin, y: canadaRect.origin.y), size: MKMapSize(width: newWidth, height: 0.0))
            mapView.setVisibleMapRect(mapRect, animated: true)
        }
    }


    // MARK: Notifications

    private func subscribeToNotifications() {
        for notification in MapNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let id = info[Keys.id] as? Int else {
            return
        }

        switch notification.name {
        case MapNotification.position.name:
            resetTimer?.invalidate()
            if let mapJSON = info[Keys.map] as? JSON, let fromGroup = info[Keys.group] as? Int, let mapRect = MKMapRect(json: mapJSON), let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture), let animated = info[Keys.animated] as? Bool {
                setMapState(from: id, group: fromGroup, momentum: state == .momentum)
                handle(mapRect, from: id, group: fromGroup, animated: animated)
            }
        case MapNotification.unpair.name:
            unpair(from: id)
        case MapNotification.ungroup.name:
            beginResetTimer()
            if let fromGroup = info[Keys.group] as? Int {
                ungroup(from: fromGroup)
            }
        case MapNotification.reset.name:
            reset()
        case MapNotification.toggleBorderOn.name:
            if id == mapID {
                border?.isHidden = false
            }
        case MapNotification.toggleBorderOff.name:
            if id == mapID {
                border?.isHidden = true
            }
        case MapNotification.toggleSwitch.name:
            if id == mapID, let switchType = info[Keys.switchType] as? Int, let type = SettingsTypes(rawValue: switchType), let toggleOn = info[Keys.toggleOn] as? Bool {
                mapViewController.toggle(switchType: type, toggleOn: toggleOn)
            }
        default:
            return
        }
    }


    // MARK: Helpers

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    private func handle(_ mapRect: MKMapRect, from id: Int, group: Int, animated: Bool) {
        guard let currentGroup = mapState.group, currentGroup == group, currentGroup == id else {
            return
        }

        // Filter position updates; state will be nil receiving when receiving from momentum, else id must match pair
        if mapState.pair == nil || mapState.pair! == id {
            activityState = .active
            set(mapRect, from: id, animated: animated)
        }
    }

    /// Sets the visble rect of self.mapView based on the current pairedID, else self.mapID
    private func set(_ mapRect: MKMapRect, from pair: Int?, animated: Bool) {
        var xOrigin = 0.0
        let pairedID = pair ?? mapID
        let canadaRect = MapConstants.canadaRect
        if mapRect.origin.x > MKMapSizeWorld.width - mapRect.size.width {
            xOrigin = mapRect.origin.x - MKMapSizeWorld.width + Double(mapID - pairedID) * mapRect.size.width
        } else {
            xOrigin = mapRect.origin.x + Double(mapID - pairedID) * mapRect.size.width
        }

        var yOrigin = mapRect.origin.y
        if xOrigin > canadaRect.origin.x + canadaRect.size.width {
            let distance = xOrigin - canadaRect.origin.x + mapRect.size.width
            xOrigin = distance.truncatingRemainder(dividingBy: canadaRect.size.width + mapRect.size.width) - mapRect.size.width + canadaRect.origin.x
        } else if xOrigin + mapRect.size.width < canadaRect.origin.x {
            let distance = canadaRect.size.width + canadaRect.origin.x - xOrigin
            xOrigin = canadaRect.origin.x + canadaRect.size.width - distance.truncatingRemainder(dividingBy: canadaRect.size.width + mapRect.size.width)
        }

        if mapRect.origin.y + mapRect.size.height * Constants.verticalVisibleMapRatio > Constants.verticalPanLimit {
            yOrigin = Constants.verticalPanLimit - mapRect.size.height * Constants.verticalVisibleMapRatio
        }

        let mapOrigin = MKMapPointMake(xOrigin, yOrigin)
        mapView.setVisibleMapRect(MKMapRect(origin: mapOrigin, size: mapRect.size), animated: animated)
    }

    /// If paired to the given id, will unpair else ignore
    private func unpair(from id: Int) {
        for (map, state) in stateForMap.enumerated() {
            if let currentPair = state.pair, currentPair == id {
                stateForMap[map] = MapState(pair: nil, group: state.group)
            }
        }
    }

    /// Ungroup all maps from group with given id
    private func ungroup(from id: Int) {
        // Clear groups with given id
        for (map, state) in stateForMap.enumerated() {
            if let currentGroup = state.group, currentGroup == id {
                stateForMap[map] = MapState(pair: nil, group: nil)
            }
        }
        // Find the closest group for all ungrouped maps
        for (map, state) in stateForMap.enumerated() {
            if state.group == nil {
                let group = findGroupForMap(id: map)
                stateForMap[map] = MapState(pair: nil, group: group)
            }
        }
    }

    /// Set all map states accordingly when a map sends its position
    private func setMapState(from id: Int, group: Int, momentum: Bool = false) {
        for (map, state) in stateForMap.enumerated() {
            // Check for current group
            if let mapGroup = state.group, mapGroup == group {
                // Once paired with own screen, don't group to other screens
                if screen(of: mapGroup) == screen(of: map) && screen(of: map) != screen(of: id) {
                    continue
                }
                // Only listen to the closest screen once paired
                if abs(screen(of: map) - screen(of: id)) >= abs(screen(of: map) - screen(of: mapGroup)), screen(of: id) != screen(of: group) {
                    continue
                }

                // Check for current pair
                if let mapPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(map - id) < abs(map - mapPair) {
                        stateForMap[map] = MapState(pair: id, group: id)
                    }
                } else if !momentum {
                    stateForMap[map] = MapState(pair: id, group: id)
                }
            } else if state.group == nil {
                stateForMap[map] = MapState(pair: id, group: id)
            }
        }
    }

    /// Find the closest group to a given map
    private func findGroupForMap(id: Int) -> Int? {
        let sortedMapStates = stateForMap.enumerated().sorted {
            if screen(of: $0.0) == screen(of: $1.0) {
                return abs(id - $0.0) < abs(id - $1.0)
            }
            return abs(screen(of: id) - screen(of: $0.0)) < abs(screen(of: id) - screen(of: $1.0))
        }

        let externalMaps = sortedMapStates.dropFirst()
        return externalMaps.compactMap({ $0.1.group }).first
    }

    /// Returns the screen id of the given map id
    private func screen(of id: Int) -> Int {
        return (id / Configuration.mapsPerScreen) + 1
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Constants.ungroupTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func beginResetTimer() {
        if mapID == Constants.masterID {
            resetTimer?.invalidate()
            resetTimer = Timer.scheduledTimer(withTimeInterval: Constants.resetTimeoutPeriod, repeats: false) { [weak self] _ in
                self?.resetTimerFired()
            }
        }
    }

    private func resetTimerFired() {
        let info: JSON = [Keys.id: mapID]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.reset.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    private func ungroupTimerFired() {
        guard let group = mapState.group, group == mapID else {
            return
        }

        if activityState == .idle {
            let info: JSON = [Keys.id: mapID, Keys.group: mapID]
            DistributedNotificationCenter.default().postNotificationName(MapNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
