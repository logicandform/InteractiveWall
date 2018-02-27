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
    private var userState = UserActivity.idle
    private weak var activityTimer: Foundation.Timer?
    private var unpaired: Bool {
        return pairedIndex == nil
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
        static let gesture = "gestureType"
    }


    // MARK: Init

    init(mapView: MKMapView, id: Int) {
        self.mapView = mapView
        self.mapID = id
        subscribeToNotifications()
    }


    // MARK: API

    func send(_ mapRect: MKMapRect, for type: GestureType = .custom) {
        let json: [String: Any] = [Keys.id: mapID, Keys.map: mapRect.toJSON(), Keys.gesture: type.rawValue]
        DistributedNotificationCenter.default().postNotificationName(MapNotifications.positionChanged.name, object: nil, userInfo: json, deliverImmediately: true)
    }

    func endUpdates() {
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
        guard let userInfo = notification.userInfo, let mapID = userInfo[Keys.id] as? Int else {
            return
        }

        switch notification.name {
        case MapNotifications.positionChanged.name:
            if let mapJSON = userInfo[Keys.map] as? [String: Any], let mapRect = MKMapRect(fromJSON: mapJSON), let gesture = userInfo[Keys.gesture] as? String, let gestureType = GestureType(rawValue: gesture) {
                handle(mapRect, fromIndex: mapID, from: gestureType)
            }
        case MapNotifications.endedActivity.name:
            unpair(from: mapID)
        default:
            return
        }

    }


    // MARK: Helpers

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    private func handle(_ mapRect: MKMapRect, fromIndex: Int, from type: GestureType) {
        if fromIndex == mapID {
            userState = .active
            pairedIndex = mapID
            if type == .system {
                return
            }
        } else if unpaired {
            pairedIndex = fromIndex
        } else if abs(mapID - fromIndex) < abs(mapID - pairedIndex!) {
            pairedIndex = fromIndex
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
    func unpair(from index: Int) {
        pairedIndex = pairedIndex == index ? nil : pairedIndex
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
            let json: [String: Any] = [Keys.id: mapID]
            DistributedNotificationCenter.default().postNotificationName(MapNotifications.endedActivity.name, object: nil, userInfo: json, deliverImmediately: true)
        }
    }
}
