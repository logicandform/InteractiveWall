//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


typealias MapState = (pair: Int?, group: Int?)


class MapHandler {

    let mapView: MKMapView
    let mapID: Int

    private var activityState = UserActivity.idle
    private var stateForMap: [MapState]
    private weak var ungroupTimer: Foundation.Timer?
    private weak var resetTimer: Foundation.Timer?

    private var mapState: MapState {
        return stateForMap[mapID]
    }


    private struct Constants {
        static let ungroupTimeoutPeriod: TimeInterval = 5
        static let resetTimeoutPeriod: TimeInterval = 5
        static let initialMapOrigin = MKMapPointMake(5250000, 70000000)
        static let initialMapSize = MKMapSizeMake(110000000.0 / Double(Configuration.mapsPerScreen), 0)
        static let canada = MKMapRect(origin: MKMapPoint(x: 23000000, y: 13000000), size: MKMapSize(width: 80000000, height: 0))
        static let verticalPanLimit: Double = 140000000
        static let masterID = 0
    }

    private struct Keys {
        static let id = "id"
        static let map = "map"
        static let group = "group"
        static let gesture = "gestureType"
    }


    // MARK: Init

    init(mapView: MKMapView, id: Int) {
        self.mapView = mapView
        self.mapID = id
        let numberOfMaps = Configuration.mapsPerScreen * Configuration.numberOfScreens
        let initialState = MapState(pair: nil, group: nil)
        self.stateForMap = Array(repeating: initialState, count: numberOfMaps)

        subscribeToNotifications()
    }


    // MARK: API

    func send(_ mapRect: MKMapRect, for gestureState: GestureState = .recognized) {
        // If sent from momentum, check if another map has interrupted
        if gestureState == .momentum && mapState.pair != nil {
            return
        }

        let group = mapState.group ?? mapID
        let info: JSON = [Keys.id: mapID, Keys.group: group, Keys.map: mapRect.toJSON(), Keys.gesture: gestureState.rawValue]
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
        var mapRect = MKMapRect(origin: Constants.canada.origin, size: MKMapSize(width: Constants.canada.size.width / Configuration.mapsPerScreen, height: 0.0))
        mapRect.origin.x = Constants.canada.origin.x + Double(mapID).truncatingRemainder(dividingBy: Configuration.mapsPerScreen) * Constants.canada.size.width / Configuration.mapsPerScreen
        mapView.setVisibleMapRect(mapRect, animated: true)
    }


    // MARK: Notifications

    private func subscribeToNotifications() {
        for notification in MapNotification.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let fromID = info[Keys.id] as? Int else {
            return
        }

        switch notification.name {
        case MapNotification.position.name:
            resetTimer?.invalidate()
            if let mapJSON = info[Keys.map] as? JSON, let fromGroup = info[Keys.group] as? Int, let mapRect = MKMapRect(json: mapJSON), let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture) {
                setMapState(from: fromID, group: fromGroup, momentum: state == .momentum)
                handle(mapRect, from: fromID, group: fromGroup)
            }
        case MapNotification.unpair.name:
            unpair(from: fromID)
        case MapNotification.ungroup.name:
            beginResetTimer()
            if let fromGroup = info[Keys.group] as? Int {
                ungroup(from: fromGroup)
            }
        case MapNotification.reset.name:
            reset()
        default:
            return
        }
    }


    // MARK: Helpers

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    private func handle(_ mapRect: MKMapRect, from id: Int, group: Int) {
        guard let currentGroup = mapState.group, currentGroup == group else {
            return
        }

        // State will be nil receiving when receiving from momentum, else make sure id matches pair
        if mapState.pair == nil || mapState.pair! == id {
            activityState = .active
            set(mapRect, from: id)
        }
    }

    /// Sets the visble rect of self.mapView based on the current pairedID, else self.mapID
    private func set(_ mapRect: MKMapRect, from pair: Int?) {
        var xOrigin = 0.0
        let pairedID = pair ?? mapID
        if mapRect.origin.x > MKMapSizeWorld.width - mapRect.size.width {
            xOrigin = mapRect.origin.x - MKMapSizeWorld.width + Double(mapID - pairedID) * mapRect.size.width
        } else {
            xOrigin = mapRect.origin.x + Double(mapID - pairedID) * mapRect.size.width

        }

        var yOrigin = mapRect.origin.y
        if xOrigin > Constants.canada.origin.x + Constants.canada.size.width {
            let distance = xOrigin - Constants.canada.origin.x + mapRect.size.width
            xOrigin = distance.truncatingRemainder(dividingBy: Constants.canada.size.width + mapRect.size.width) - mapRect.size.width + Constants.canada.origin.x
        } else if xOrigin + mapRect.size.width < Constants.canada.origin.x {
            let distance = Constants.canada.size.width + Constants.canada.origin.x - xOrigin
            xOrigin = Constants.canada.origin.x + Constants.canada.size.width - distance.truncatingRemainder(dividingBy: Constants.canada.size.width + mapRect.size.width)
        } 

        if mapRect.origin.y + mapRect.size.height > Constants.verticalPanLimit {
            yOrigin = Constants.verticalPanLimit - mapRect.size.height
        }

        let mapOrigin = MKMapPointMake(xOrigin, yOrigin)
        mapView.visibleMapRect.size = mapRect.size
        mapView.visibleMapRect.origin = mapOrigin
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
            if let currentGroup = state.group, currentGroup == group {
                // Check for current pair
                if let currentPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(map - id) < abs(map - currentPair) {
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
        let sortedMapStates = stateForMap.enumerated().sorted { abs(id - $0.0) < abs(id - $1.0) }
        let externalMaps = sortedMapStates.dropFirst()
        return externalMaps.compactMap({ $0.1.group }).first
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
            resetTimer = Timer.scheduledTimer(withTimeInterval: Constants.resetTimeoutPeriod, repeats: false) { [weak self] _ in
                let info: JSON = [Keys.id: self?.mapID]
                DistributedNotificationCenter.default().postNotificationName(MapNotification.reset.name, object: nil, userInfo: info, deliverImmediately: true)
            }
        }
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
