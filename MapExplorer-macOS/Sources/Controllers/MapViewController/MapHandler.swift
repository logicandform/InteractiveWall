//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class MapHandler {

    let mapView: MKMapView
    let mapID: Int

    private var pairedID: Int?
    private var groupID: Int?
    private weak var activityTimer: Foundation.Timer?

    private var unpaired: Bool {
        return pairedID == nil
    }

    private var ungrouped: Bool {
        return groupID == nil
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

    func send(_ mapRect: MKMapRect, for state: GestureState = .recognized) {
        let group = groupID ?? mapID
        if state != .momentum {
            pairedID = mapID
            groupID = mapID
        }

        if unpaired || groupID == mapID {
            let info: JSON = [Keys.id: mapID, Keys.group: group, Keys.map: mapRect.toJSON(), Keys.gesture: state.rawValue]
            DistributedNotificationCenter.default().postNotificationName(MapNotifications.positionChanged.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }

    func endActivity() {
        pairedID = nil
        let info: JSON = [Keys.id: mapID]
        DistributedNotificationCenter.default().postNotificationName(MapNotifications.endedActivity.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
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
        guard let info = notification.userInfo, let fromID = info[Keys.id] as? Int else {
            return
        }

        switch notification.name {
        case MapNotifications.positionChanged.name:
            if let mapJSON = info[Keys.map] as? JSON, let fromGroup = info[Keys.group] as? Int, let mapRect = MKMapRect(json: mapJSON), let gesture = info[Keys.gesture] as? String, let state = GestureState(rawValue: gesture) {
                handle(mapRect, fromID: fromID, inGroup: fromGroup, from: state)
            }
        case MapNotifications.endedActivity.name:
            unpair(from: fromID)
        case MapNotifications.endedUpdates.name:
            if let groupID = info[Keys.group] as? Int {
                ungroup(from: groupID)
            }
        default:
            return
        }
    }


    // MARK: Helpers

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    private func handle(_ mapRect: MKMapRect, fromID: Int, inGroup group: Int, from state: GestureState) {
        var pair: Int? = nil
        if ungrouped {
            pairedID = fromID
            groupID = fromID
        } else if groupID! == group, unpaired {
            if fromID != mapID {
                if state == .momentum {
                    pair = fromID
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

        if pair == nil {
            pair = pairedID
        }

        set(mapRect, from: pair)
    }

    /// Sets the visble rect of self.mapView based on the current pairedID
    private func set(_ mapRect: MKMapRect, from pair: Int?) {
        let pairedID = pair ?? mapID
        let xOrigin = mapRect.origin.x + Double(mapID - pairedID) * mapRect.size.width
        let mapOrigin = MKMapPointMake(xOrigin, mapRect.origin.y)

        mapView.visibleMapRect.size = mapRect.size
        mapView.visibleMapRect.origin = mapOrigin
    }

    /// If paired to the given id, will unpair else ignore
    func unpair(from id: Int) {
        pairedID = pairedID == id ? nil : pairedID
    }

    func ungroup(from id: Int) {
        groupID = groupID == id ? nil : groupID
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginActivityTimeout() {
        activityTimer?.invalidate()
        activityTimer = Timer.scheduledTimer(withTimeInterval: Constants.activityTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.activityTimeoutFired()
        }
    }

    private func activityTimeoutFired() {
        guard let groupID = groupID, groupID == mapID else {
            return
        }

        let info: JSON = [Keys.id: mapID, Keys.group: groupID]
        DistributedNotificationCenter.default().postNotificationName(MapNotifications.endedUpdates.name, object: nil, userInfo: info, deliverImmediately: true)
    }
}
