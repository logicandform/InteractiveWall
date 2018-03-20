//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class MapHandler {

    let mapView: MKMapView
    let mapID: Int

    private var pairedID: Int?
    private var groupID: Int?
    private var state = UserActivity.idle
    private weak var ungroupTimer: Foundation.Timer?
    private var groupForMap = [Int: Int?]()

    private var unpaired: Bool {
        return pairedID == nil
    }

    private var ungrouped: Bool {
        return groupID == nil
    }

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
        subscribeToNotifications()
    }


    // MARK: API

    func send(_ mapRect: MKMapRect, for gestureState: GestureState = .recognized) {
        let group = groupID ?? mapID
        if gestureState != .momentum {
            pairedID = mapID
            groupID = mapID
        }

        if unpaired || groupID == mapID {
            let info: JSON = [Keys.id: mapID, Keys.group: group, Keys.map: mapRect.toJSON(), Keys.gesture: gestureState.rawValue]
            DistributedNotificationCenter.default().postNotificationName(MapNotifications.position.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }

    func endActivity() {
        pairedID = nil
        let info: JSON = [Keys.id: mapID]
        DistributedNotificationCenter.default().postNotificationName(MapNotifications.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        state = .idle
        beginUngroupTimer()
    }

    func reset() {
        var mapRect = MKMapRect(origin: Constants.initialMapOrigin, size: Constants.initialMapSize)
        mapRect.origin.x = Constants.initialMapOrigin.x + Double(mapID) * Constants.initialMapSize.width
        mapView.visibleMapRect = mapRect
    }


    // MARK: Notifications

    private func subscribeToNotifications() {
        for notification in MapNotifications.allValues {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
    }

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo, let fromID = info[Keys.id] as? Int else {
            return
        }

        switch notification.name {
        case MapNotifications.position.name:
            if let mapJSON = info[Keys.map] as? JSON, let fromGroup = info[Keys.group] as? Int, let mapRect = MKMapRect(json: mapJSON), let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture) {
                updateMappings(fromGroup: fromGroup, to: fromID)
                handle(mapRect, fromID: fromID, inGroup: fromGroup, from: state)
            }
        case MapNotifications.unpair.name:
            unpair(from: fromID)
        case MapNotifications.ungroup.name:
            if let fromGroup = info[Keys.group] as? Int {
                print("ungroup from \(fromGroup)")
                updateMappings(fromGroup: fromGroup, to: nil)
                ungroup(from: fromGroup)
                findGroupIfNeeded()
            }
        default:
            return
        }
    }


    // MARK: Helpers

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    private func handle(_ mapRect: MKMapRect, fromID: Int, inGroup group: Int, from gestureState: GestureState) {
        if ungrouped {
            pairedID = fromID
            groupID = fromID
        } else if groupID! == group, unpaired {
            if fromID != mapID {
                if gestureState == .momentum {
                    set(mapRect, from: fromID)
                    return
                } else {
                    pairedID = fromID
                    groupID = fromID
                }
            }
        } else if groupID! == group, abs(mapID - fromID) < abs(mapID - pairedID!) {
            pairedID = fromID
            groupID = fromID
        } else if groupID! != group || fromID != pairedID {
            return
        }

        state = .active
        set(mapRect, from: pairedID)
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
        pairedID = pairedID == id ? nil : pairedID
    }

    private func ungroup(from id: Int) {
        groupID = groupID == id ? nil : groupID
    }

    private func updateMappings(fromGroup: Int, to id: Int?) {
        let maps = Configuration.mapsPerScreen * Configuration.numberOfScreens
        for map in (0..<maps) {
            if let id = id, id == map {
                groupForMap[map] = id
            } else if let group = groupForMap[map] {
                if group == fromGroup {
                    groupForMap[map] = id
                }
            } else {
                groupForMap[map] = id
            }
        }
    }

    private func findGroupIfNeeded() {
        if groupID != nil {
            return
        }

        let maps = Configuration.mapsPerScreen * Configuration.numberOfScreens
        let checks = maps - mapID
        for offset in (1...checks) {
            let lhs = mapID - offset
            let rhs = mapID + offset
            if lhs >= 0, let lhsGroup = groupForMap[lhs], lhsGroup != nil {
                groupID = lhsGroup
                return
            } else if rhs < maps, let rhsGroup = groupForMap[rhs], rhsGroup != nil {
                groupID = rhsGroup
                return
            }
        }
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Constants.ungroupTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func ungroupTimerFired() {
        guard let groupID = groupID, groupID == mapID else {
            return
        }

        if state == .idle {
            let info: JSON = [Keys.id: mapID, Keys.group: groupID]
            DistributedNotificationCenter.default().postNotificationName(MapNotifications.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
