//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


private enum UserActivity {
    case idle
    case active
}


class MapHandler {

    let mapView: MKMapView
    let mapID: Int

    private var pair: Int? {
        return ConnectionManager.instance.pairForApp(id: appID)
    }

    private var group: Int? {
        return ConnectionManager.instance.groupForApp(id: appID)
    }

    /// The state for a map indexed by it's mapID
    private var activityState = UserActivity.idle
    private weak var ungroupTimer: Foundation.Timer?

    private struct Constants {
        static let ungroupTimeoutPeriod: TimeInterval = 30
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

    init(mapView: MKMapView, id: Int) {
        self.mapView = mapView
        self.mapID = id
    }


    // MARK: API

    /// Determines how to respond to a received mapRect from another mapView and the type of gesture that triggered the event.
    func handle(_ mapRect: MKMapRect, fromID: Int, fromGroup: Int, animated: Bool) {
        guard let currentGroup = group, currentGroup == fromGroup, currentGroup == fromID else {
            return
        }

        // Filter position updates; state will be nil receiving when receiving from momentum, else id must match pair
        if pair == nil || pair! == fromID {
            activityState = .active
            let adjustedMapRect = adjust(mapRect, toMap: mapID, fromMap: fromID)
            mapView.setVisibleMapRect(adjustedMapRect, animated: animated)
        }
    }

    func send(_ mapRect: MKMapRect, for gestureState: GestureState = .recognized, animated: Bool = false, forced: Bool = false) {
        // If sending from momentum but another map has interrupted, ignore
        if gestureState == .momentum && pair != nil && !forced {
            return
        }

        let currentGroup = group ?? mapID
        let info: JSON = [Keys.id: mapID, Keys.group: currentGroup, Keys.map: mapRect.toJSON(), Keys.gesture: gestureState.rawValue, Keys.animated: animated]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.position.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endActivity() {
        ConnectionManager.instance.set(state: AppState(pair: nil, group: group, type: .mapExplorer), forApp: appID)
        let info: JSON = [Keys.id: mapID]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        activityState = .idle
        beginUngroupTimer()
    }

    func reset(animated: Bool = true) {
        let canadaRect = MapConstants.canadaRect
        if Configuration.appsPerScreen == 1 {
            mapView.setVisibleMapRect(MKMapRect(origin: canadaRect.origin, size: canadaRect.size), animated: true)
        } else {
            let newWidth = canadaRect.size.width / (Double(Configuration.appsPerScreen) - 1.0)
            let newXOrigin = ((Double(mapID).truncatingRemainder(dividingBy: Double(Configuration.appsPerScreen)) * newWidth) - (newWidth / 2)) + canadaRect.origin.x
            let mapRect = MKMapRect(origin: MKMapPoint(x: newXOrigin, y: canadaRect.origin.y), size: MKMapSize(width: newWidth, height: 0.0))
            mapView.setVisibleMapRect(mapRect, animated: true)
        }
    }


    // MARK: Helpers

    private func adjust(_ mapRect: MKMapRect, toMap map: Int, fromMap pair: Int?) -> MKMapRect {
        var xOrigin = 0.0
        let pairedID = pair ?? map
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

        return MKMapRect(origin: MKMapPointMake(xOrigin, yOrigin), size: mapRect.size)
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Constants.ungroupTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func ungroupTimerFired() {
        guard let group = group, group == mapID else {
            return
        }

        if activityState == .idle {
            let info: JSON = [Keys.id: mapID, Keys.group: mapID]
            DistributedNotificationCenter.default().postNotificationName(MapNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }
}
