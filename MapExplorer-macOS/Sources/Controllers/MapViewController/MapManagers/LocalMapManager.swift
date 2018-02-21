//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class LocalMapManager {

    /// A collection of mapviews, indexed by their position, left -> right across windows
    private var handlerForMapView = [MKMapView: MapHandler]()
    private weak var longActivityTimer: Foundation.Timer?

    private struct Constants {
        static let longActivityTimeoutPeriod: TimeInterval = 10
    }


    // MARK: API

    func add(_ maps: [MKMapView]) {
        for mapView in maps {
            let id = handlerForMapView.count
            handlerForMapView[mapView] = MapHandler(mapView: mapView, id: id)
        }
    }

    func set(_ mapRect: MKMapRect, of mapView: MKMapView) {
        guard let index = handlerForMapView[mapView]?.mapID else {
            return
        }

        for handler in handlerForMapView.values {
            handler.handle(mapRect, fromIndex: index)
        }
        beginLongActivityTimeout()
    }

    func finishedUpdating(_ mapView: MKMapView) {
        if let handler = handlerForMapView[mapView] {
            handler.endUpdates()
        }
    }

    /// Sync all maps to an initial region
    func reset() {

    }


    // MARK: Helpers

    /// If running on the master device, resets all devices after a timeout period
    private func beginLongActivityTimeout() {
        longActivityTimer?.invalidate()
        longActivityTimer = Timer.scheduledTimer(withTimeInterval: Constants.longActivityTimeoutPeriod, repeats: false) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }

            // Ensure that all map handlers are idle
            if strongSelf.isIdle() {
                strongSelf.reset()
            }
        }
    }

    /// Returns true if there is no current user activity
    private func isIdle() -> Bool {
        for handler in handlerForMapView.values {
            if handler.isActive() {
                return false
            }
        }

        return true
    }
}
