//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit
import MacGestures


enum UserActivity {
    case idle
    case active
}


final class MapHandler {

    let mapView: MKMapView
    weak var mapViewController: MapViewController?
    private var activityState = UserActivity.idle
    private var animationStart: Date?
    private weak var ungroupTimer: Foundation.Timer?
    private weak var animationTimer: Foundation.Timer?

    private var pair: Int? {
        return ConnectionManager.instance.pairForApp(id: appID, type: .mapExplorer)
    }

    private var group: Int? {
        return ConnectionManager.instance.groupForApp(id: appID, type: .mapExplorer)
    }

    private var animating: Bool {
        return animationStart != nil
    }

    private struct Constants {
        static let verticalPanLimit = 100000000.0
        static let verticalVisibleMapRatio = 0.25
        static let downTimeAfterSentAnimated = 0.2
        static let accountForDateLineThreshold = 214000000.0
    }

    private struct Keys {
        static let id = "id"
        static let map = "map"
        static let type = "type"
        static let group = "group"
        static let gesture = "gestureType"
    }


    // MARK: Init

    init(mapView: MKMapView, controller: MapViewController) {
        self.mapView = mapView
        self.mapViewController = controller
    }

    deinit {
        ungroupTimer?.invalidate()
        animationTimer?.invalidate()
    }


    // MARK: API

    /// Determines how to respond to a received mapRect from another mapView with the type of gesture that triggered the event.
    func handle(_ mapRect: MKMapRect, fromID: Int, syncing: Bool = false) {
        guard let currentGroup = group, currentGroup == fromID else {
            return
        }

        // Filter position updates; state will be nil receiving when receiving from momentum or animation, else id must match pair
        if pair == nil || pair! == fromID {
            if !syncing {
                activityState = .active
            }
            let adjustedMapRect = adjust(mapRect, toMap: appID, fromMap: fromID)
            mapView.setVisibleMapRect(adjustedMapRect, animated: false)
        }
    }

    func handleReset(_ mapRect: MKMapRect, fromID: Int) {
        if group == nil {
            let adjustedMapRect = adjust(mapRect, toMap: appID, fromMap: fromID)
            mapView.setVisibleMapRect(adjustedMapRect, animated: false)
        }
    }

    func send(_ mapRect: MKMapRect, for gestureState: GestureState = .recognized) {
        // If sending from momentum or an animation but another map has interrupted or just sent animated, ignore
        if gestureState.interruptible && pair != nil {
            return
        }

        // Stop animating if necessary
        endAnimation()

        let currentGroup = group ?? appID
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.map: mapRect.toJSON(), Keys.gesture: gestureState.rawValue]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.mapRect.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    /// Replaces apples setVisibleMapRect animationed which has a bug
    func animate(to mapRect: MKMapRect, type: MapAnimationType) {
        var initialOrigin = mapView.visibleMapRect.origin
        let finalOrigin = mapRect.origin

        // Adjust for international date line if necessairy
        switch type {
        case .clusterTap where finalOrigin.x < initialOrigin.x, .doubleTap where finalOrigin.x < initialOrigin.x:
            initialOrigin.x -= MKMapRect.world.size.width
        case .reset where initialOrigin.x > Constants.accountForDateLineThreshold:
            initialOrigin.x -= MKMapRect.world.size.width
        default:
            break
        }

        let originVector = finalOrigin - initialOrigin
        let initialMapRect = mapView.visibleMapRect
        let scale = mapRect.size.width / initialMapRect.size.width

        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: GestureManager.refreshRate, repeats: true) { [weak self] _ in
            self?.animationTimerFired(for: type, initialMapRect: initialMapRect, originVector: originVector, scale: scale)
        }
    }

    /// Sends a mapRect to sync all apps in the same group
    func syncGroup() {
        let currentGroup = group ?? appID
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.map: mapView.visibleMapRect.toJSON()]
        DistributedNotificationCenter.default().postNotificationName(MapNotification.sync.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endActivity() {
        ConnectionManager.instance.set(AppState(pair: nil, group: group), for: .mapExplorer, id: appID)
        let info: JSON = [Keys.id: appID, Keys.type: ApplicationType.mapExplorer.rawValue]
        DistributedNotificationCenter.default().postNotificationName(SettingsNotification.unpair.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func endUpdates() {
        activityState = .idle
        beginUngroupTimer()
    }

    func endAnimation() {
        animationTimer?.invalidate()
        animationStart = nil
    }

    func reset(animated: Bool) {
        let canadaRect = MapConstants.canadaRect
        let width = canadaRect.size.width / Double(Configuration.appsPerScreen)
        let offset = width / Double(Configuration.appsPerScreen)
        let originX = appID.isEven ? canadaRect.origin.x - offset : canadaRect.origin.x + width - offset
        let mapRect = MKMapRect(origin: MKMapPoint(x: originX, y: canadaRect.origin.y), size: MKMapSize(width: width, height: 0)).withPreservedAspectRatio(in: mapView)
        let centerAppID = (Configuration.numberOfScreens * Configuration.appsPerScreen - 1) / 2

        if animated && appID == centerAppID {
            animate(to: mapRect, type: .reset)
        } else if !animated {
            mapView.setVisibleMapRect(mapRect, animated: false)
        }
    }


    // MARK: Helpers

    private func adjust(_ mapRect: MKMapRect, toMap map: Int, fromMap pair: Int?) -> MKMapRect {
        let pairedID = pair ?? map
        let canadaRect = MapConstants.canadaRect
        let offsetWidth = canadaRect.size.width / Double(Configuration.appsPerScreen)

        var xOrigin = (mapRect.origin.x + mapRect.size.width).truncatingRemainder(dividingBy: MKMapSize.world.width) - mapRect.size.width + Double(appID - pairedID) * mapRect.size.width
        var yOrigin = mapRect.origin.y

        if xOrigin > canadaRect.origin.x + offsetWidth {
            let distance = xOrigin - canadaRect.origin.x + mapRect.size.width
            xOrigin = distance.truncatingRemainder(dividingBy: offsetWidth + mapRect.size.width) - mapRect.size.width + canadaRect.origin.x
        } else if xOrigin + mapRect.size.width < canadaRect.origin.x {
            let distance = offsetWidth + canadaRect.origin.x - xOrigin
            xOrigin = canadaRect.origin.x + offsetWidth - distance.truncatingRemainder(dividingBy: offsetWidth + mapRect.size.width)
        }

        if mapRect.origin.y + mapRect.size.height * Constants.verticalVisibleMapRatio > Constants.verticalPanLimit {
            yOrigin = Constants.verticalPanLimit - mapRect.size.height * Constants.verticalVisibleMapRatio
        }

        return MKMapRect(origin: MKMapPoint(x: xOrigin, y: yOrigin), size: mapRect.size)
    }

    /// Resets the pairedDeviceID after a timeout period
    private func beginUngroupTimer() {
        ungroupTimer?.invalidate()
        ungroupTimer = Timer.scheduledTimer(withTimeInterval: Configuration.ungroupTimoutDuration, repeats: false) { [weak self] _ in
            self?.ungroupTimerFired()
        }
    }

    private func ungroupTimerFired() {
        if let group = group, group == appID, activityState == .idle {
            let info: JSON = [Keys.id: appID, Keys.type: ApplicationType.mapExplorer.rawValue, Keys.group: appID]
            DistributedNotificationCenter.default().postNotificationName(SettingsNotification.ungroup.name, object: nil, userInfo: info, deliverImmediately: true)
        }
    }

    /// Handles moving the map in small increment to the final position (i.e animating)
    private func animationTimerFired(for type: MapAnimationType, initialMapRect: MKMapRect, originVector: MKMapPoint, scale: Double) {
        if !animating {
            animationStart = Date()
        } else if pair != nil {
            // End animation if interrupted
            endAnimation()
            return
        }

        let progress = min(1.0, abs(animationStart!.timeIntervalSinceNow) / type.duration)

        // Accounts for international date line
        let originX = (initialMapRect.origin.x + originVector.x * progress).truncatingRemainder(dividingBy: MKMapRect.world.size.width)
        let originY = initialMapRect.origin.y + originVector.y * progress
        let size = MKMapSize(width: initialMapRect.size.width - initialMapRect.size.width * (1 - scale) * progress, height: initialMapRect.size.height - initialMapRect.size.height * (1 - scale) * progress)
        let mapRect = MKMapRect(origin: MKMapPoint(x: originX, y: originY), size: size)
        let currentGroup = group ?? appID
        let info: JSON = [Keys.id: appID, Keys.group: currentGroup, Keys.map: mapRect.toJSON(), Keys.gesture: GestureState.animated.rawValue]
        DistributedNotificationCenter.default().postNotificationName(type.notification.name, object: nil, userInfo: info, deliverImmediately: true)

        if progress == 1 {
            endAnimation()
            endUpdates()
        }
    }
}
