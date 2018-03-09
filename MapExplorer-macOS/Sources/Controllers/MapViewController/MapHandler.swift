//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


enum UserActivity {
    case idle
    case active
}


class MapHandler {

    let mapView: MKMapView
    let mapID: Int

    private var pairedIndex: Int?
    private var groupIndex: Int?
    private var userState = UserActivity.idle
    private weak var activityTimer: Foundation.Timer?

    private var unpaired: Bool {
        return pairedIndex == nil
    }

    private var ungrouped: Bool {
        return groupIndex == nil
    }

    private struct Constants {
        static let activityTimeoutPeriod: TimeInterval = 4
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

    func send(_ mapRect: MKMapRect, gestureType type: GestureType = .custom) {
        let info: JSON
        if let groupID = groupIndex {
            info = [Keys.id: mapID, Keys.group: groupID, Keys.map: mapRect.toJSON(), Keys.gesture: type.rawValue]
        } else {
            info = [Keys.id: mapID, Keys.map: mapRect.toJSON(), Keys.gesture: type.rawValue]
        }
        DistributedNotificationCenter.default().postNotificationName(MapNotifications.positionChanged.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endActivity() {
        guard let groupID = groupIndex else {
            return
        }

        let info: JSON = [Keys.id: mapID, Keys.group: groupID]
        DistributedNotificationCenter.default().postNotificationName(MapNotifications.endedActivity.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        let info: JSON = [Keys.id: mapID]
        DistributedNotificationCenter.default().postNotificationName(MapNotifications.endedUpdates.name, object: nil, userInfo: info, deliverImmediately: true)
        userState = .idle
        beginActivityTimeout()
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
        guard let userInfo = notification.userInfo, let fromID = userInfo[Keys.id] as? Int else {
            return
        }

        switch notification.name {
        case MapNotifications.positionChanged.name:
            if let mapJSON = userInfo[Keys.map] as? JSON, let mapRect = MKMapRect(json: mapJSON), let gesture = userInfo[Keys.gesture] as? String, let gestureType = GestureType(rawValue: gesture) {
                let fromGroup = userInfo[Keys.group] as? Int
                handle(mapRect, fromIndex: fromID, in: fromGroup, from: gestureType)
            }
        case MapNotifications.endedActivity.name:
            deactivate(from: fromID)
        case MapNotifications.endedUpdates.name:
            if let groupID = userInfo[Keys.group] as? Int {
                ungroup(from: groupID)
            }
        default:
            return
        }

    }


    // MARK: Helpers

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    private func handle(_ mapRect: MKMapRect, fromIndex: Int, in group: Int?, from type: GestureType) {

        if ungrouped {
            groupIndex = group
            pairedIndex = fromIndex
        } else if unpaired {

        } else if fromIndex == mapID, unpaired {
            pairedIndex = mapID
            userState = .active
            if type == .system {
                return
            }
        } else if groupIndex! == group, unpaired {
            pairedIndex = fromIndex
        } else if groupIndex! == group, abs(mapID - fromIndex) < abs(mapID - pairedIndex!) {
            pairedIndex = fromIndex
        }








        if let currentGroup = groupIndex, currentGroup == group {
            pairedIndex = fromIndex
        } else if fromIndex == mapID, pairedIndex == nil {
            userState = .active
            pairedIndex = mapID
            if type == .system {
                return
            }
        } else if unpaired {
            pairedIndex = fromIndex
            groupIndex = group
        } else if abs(mapID - fromIndex) < abs(mapID - pairedIndex!) {
            pairedIndex = fromIndex
            groupIndex = group
        } else if pairedIndex != fromIndex {
            return
        }

        set(mapRect)
    }

    /// Sets the visble rect of self.mapView based on the current pairedIndex
    private func set(_ mapRect: MKMapRect) {
        guard let pairedIndex = pairedIndex else {
            return
        }

        let xOrigin = mapRect.origin.x + Double(mapID - pairedIndex) * mapRect.size.width
        let mapOrigin = MKMapPointMake(xOrigin, mapRect.origin.y)

        mapView.visibleMapRect.size = mapRect.size
        mapView.visibleMapRect.origin = mapOrigin
    }

    /// If paired to the given id, will unpair else ignore
    func deactivate(from index: Int) {
        pairedIndex = pairedIndex == index ? nil : pairedIndex
    }

    func ungroup(from index: Int) {
        groupIndex = groupIndex == index ? nil : groupIndex
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginActivityTimeout() {
        activityTimer?.invalidate()
        activityTimer = Timer.scheduledTimer(withTimeInterval: Constants.activityTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.activityTimeoutFired()
        }
    }

    private func activityTimeoutFired() {
        if userState == .idle {
            let json: JSON = [Keys.id: mapID]
            DistributedNotificationCenter.default().postNotificationName(MapNotifications.endedActivity.name, object: nil, userInfo: json, deliverImmediately: true)
        }
    }
}
