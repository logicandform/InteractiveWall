//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


protocol MapActivityDelegate: class {
    func activityEnded(for mapIndex: Int)
}

let notification = NSNotification.Name(rawValue: "TESTTT")

class LocalMapManager: MapActivityDelegate {

    private var handlerForMapView = [MKMapView: MapHandler]()
    private weak var longActivityTimer: Foundation.Timer?

    private struct Constants {
        static let longActivityTimeoutPeriod: TimeInterval = 10
    }

    init() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleEvent(_:)), name: notification, object: nil)
    }

    @objc
    private func handleEvent(_ notification: NSNotification) {
        guard let info = notification.userInfo, let mapID = info["id"] as? Int, let mapX = info["x"] as? Double, let mapY = info["y"] as? Double, let width = info["width"] as? Double, let height = info["height"] as? Double else {
            return
        }

        let mapRect = MKMapRect(origin: MKMapPoint(x: mapX, y: mapY), size: MKMapSize(width: width, height: height))
        set(mapRect, from: mapID)
    }

    private func postRect(_ mapRect: MKMapRect, for index: Int) {
        let info: [String: Any] = ["id": index, "x": mapRect.origin.x, "y": mapRect.origin.y, "width": mapRect.size.width, "height": mapRect.size.height]
        DistributedNotificationCenter.default().postNotificationName(notification, object: nil, userInfo: info, deliverImmediately: true)
    }


    // MARK: API

    func add(_ maps: [MKMapView]) {
        for mapView in maps {
            let id = handlerForMapView.count + 2
            handlerForMapView[mapView] = MapHandler(mapView: mapView, id: id, delegate: self)
        }
    }

    func set(_ mapRect: MKMapRect, from index: Int) {
        for handler in handlerForMapView.values {
            handler.handle(mapRect, fromIndex: index)
        }

        //        beginLongActivityTimeout()
    }

    func set(_ mapRect: MKMapRect, of mapView: MKMapView) {
        guard let index = handlerForMapView[mapView]?.mapID else {
            return
        }

//        for handler in handlerForMapView.values {
//            handler.handle(mapRect, fromIndex: index)
//        }

        postRect(mapRect, for: index)

//        beginLongActivityTimeout()
    }

    func finishedUpdating(_ mapView: MKMapView) {
        if let handler = handlerForMapView[mapView] {
            handler.endUpdates()
        }
    }

    /// Sync all maps to an initial region
    func reset() {
        for handler in handlerForMapView.values {
            handler.reset()
        }
    }


    // MARK: MapActivityDelegate

    func activityEnded(for mapIndex: Int) {
        for handler in handlerForMapView.values {
            handler.unpair(from: mapIndex)
        }
    }


    // MARK: Helpers

    /// If running on the master device, resets all devices after a timeout period
    private func beginLongActivityTimeout() {
        longActivityTimer?.invalidate()
        longActivityTimer = Timer.scheduledTimer(withTimeInterval: Constants.longActivityTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.longActivityFired()
        }
    }

    /// Resets all maps if there is no user activity.
    private func longActivityFired() {
        for handler in handlerForMapView.values {
            if handler.isActive() {
                return
            }
        }

        reset()
    }
}
