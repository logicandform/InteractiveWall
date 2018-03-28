//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


typealias MapState = (pair: Int?, group: Int?)


class MapHandler {

    let mapView: MKMapView
    let mapID: Int

    private var activityState = UserActivity.idle
    private weak var ungroupTimer: Foundation.Timer?
    private var stateForMap = [Int: MapState]()


    private struct Constants {
        static let ungroupTimeoutPeriod: TimeInterval = 5
        static let numberOfScreens = 1.0
        static let initialMapOrigin = MKMapPointMake(6000000.0, 62000000.0)
        static let initialMapSize = MKMapSizeMake(120000000.0 / (Constants.numberOfScreens * 3), 0.0)
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
        for map in (0 ..< Configuration.mapsPerScreen * Configuration.numberOfScreens) {
            stateForMap[map] = (nil, nil)
        }
        subscribeToNotifications()
    }


    // MARK: API

    func send(_ mapRect: MKMapRect, for gestureState: GestureState = .recognized) {
        guard let state = stateForMap[mapID] else {
            return
        }

        // If sent from momentum, check if another map has interrupted
        if gestureState == .momentum && state.pair != nil {
            return
        }

        let group = state.group ?? mapID
        let info: JSON = [Keys.id: mapID, Keys.group: group, Keys.map: mapRect.toJSON(), Keys.gesture: gestureState.rawValue]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.position.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endActivity() {
        if let state = stateForMap[mapID] {
            stateForMap[mapID] = MapState(pair: nil, group: state.group)
        }
        let info: JSON = [Keys.id: mapID]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        activityState = .idle
        beginUngroupTimer()
    }

    func reset() {
        var mapRect = MKMapRect(origin: Constants.initialMapOrigin, size: Constants.initialMapSize)
        mapRect.origin.x = Constants.initialMapOrigin.x + Double(mapID) * Constants.initialMapSize.width
        mapView.visibleMapRect = mapRect
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
            if let mapJSON = info[Keys.map] as? JSON, let fromGroup = info[Keys.group] as? Int, let mapRect = MKMapRect(json: mapJSON), let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture) {
                setMapState(from: fromID, group: fromGroup, momentum: state == .momentum)
                handle(mapRect, from: fromID, group: fromGroup)
            }
        case MapNotification.unpair.name:
            unpair(from: fromID)
        case MapNotification.ungroup.name:
            if let fromGroup = info[Keys.group] as? Int {
                ungroup(from: fromGroup)
//                findGroupIfNeeded()
            }
        default:
            return
        }
    }


    // MARK: Helpers

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    private func handle(_ mapRect: MKMapRect, from id: Int, group: Int) {
        guard let state = stateForMap[mapID], let currentGroup = state.group, currentGroup == group else {
            return
        }

        // If state is nil receiving from momentum, else make sure id matches pair
        if state.pair == nil || state.pair! == id {
            activityState = .active
            set(mapRect, from: id)
        }
    }

    /// Sets the visble rect of self.mapView based on the current pairedID, else self.mapID
    private func set(_ mapRect: MKMapRect, from pair: Int?) {
        let pairedID = pair ?? mapID
        let xOrigin = mapRect.origin.x + Double(mapID - pairedID) * mapRect.size.width
        let mapOrigin = MKMapPointMake(xOrigin, mapRect.origin.y)

        mapView.visibleMapRect.size = mapRect.size
        mapView.visibleMapRect.origin = mapOrigin
    }

    /// If paired to the given id, will unpair else ignore
    private func unpair(from id: Int) {
        print("Unpairing from id: \(id)")
        for (map, state) in stateForMap {
            if let currentPair = state.pair, currentPair == id {
                stateForMap[map] = MapState(pair: nil, group: state.group)
            }
        }
    }

    private func ungroup(from id: Int) {
        print("Un-grouping from id: \(id)")
        for (map, state) in stateForMap {
            if let currentGroup = state.group, currentGroup == id {
                stateForMap[map] = MapState(pair: nil, group: nil)
            }
        }
    }

    private func setMapState(from id: Int, group: Int, momentum: Bool = false) {
        for (map, state) in stateForMap {
            // Check for current group
            if let currentGroup = state.group, currentGroup == group {
                // Check for current pair
                if let currentPair = state.pair {
                    // Check if incoming id is closer than current pair
                    if abs(map - id) < abs(map - currentPair) {
                        stateForMap[map] = MapState(pair: id, group: id)
                    }
                } else if !momentum {
                    stateForMap[map] = MapState(pair: id, group: state.group)
                }
            } else if state.group == nil {
                stateForMap[map] = MapState(pair: id, group: id)
            }
        }
    }

    private func findGroupIfNeeded() {
//        if groupID != nil {
//            return
//        }
//
//        let maps = Configuration.mapsPerScreen * Configuration.numberOfScreens
//        let checks = maps - mapID
//        for offset in (1...checks) {
//            let lhs = mapID - offset
//            let rhs = mapID + offset
//            if lhs >= 0, let lhsGroup = groupForMap[lhs], lhsGroup != nil {
//                groupID = lhsGroup
//                return
//            } else if rhs < maps, let rhsGroup = groupForMap[rhs], rhsGroup != nil {
//                groupID = rhsGroup
//                return
//            }
//        }
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Constants.ungroupTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func ungroupTimerFired() {
        guard let state = stateForMap[mapID], let group = state.group, group == mapID else {
            return
        }

        if activityState == .idle {
            let info: JSON = [Keys.id: mapID, Keys.group: mapID]
            DistributedNotificationCenter.default().postNotificationName(MapNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
