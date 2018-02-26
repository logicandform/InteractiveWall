//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


protocol MapActivityDelegate: class {
    func activityEnded(for mapIndex: Int)
}


class LocalMapManager: MapActivityDelegate {

    private var handlerForMapView = [MKMapView: MapHandler]()
    private weak var longActivityTimer: Foundation.Timer?

    private struct Constants {
        static let longActivityTimeoutPeriod: TimeInterval = 10
    }


    // MARK: API

    func add(_ maps: [MKMapView]) {
        for mapView in maps {
            let id = handlerForMapView.count
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

        for handler in handlerForMapView.values {
            handler.handle(mapRect, fromIndex: index)
        }

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
