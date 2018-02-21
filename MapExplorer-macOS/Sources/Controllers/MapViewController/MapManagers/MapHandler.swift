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
    weak var delegate: MapActivityDelegate?

    private var pairedIndex: Int?
    private var userState = UserActivity.idle
    private weak var activityTimer: Foundation.Timer?

    private var unpaired: Bool {
        return pairedIndex == nil
    }

    private struct Constants {
        static let activityTimeoutPeriod: TimeInterval = 4
    }

    // MARK: Init

    init(mapView: MKMapView, id: Int, delegate: MapActivityDelegate?) {
        self.mapView = mapView
        self.mapID = id
        self.delegate = delegate
    }


    // MARK: API

    func handle(_ mapRect: MKMapRect, fromIndex: Int) {
        if fromIndex == mapID {
            userState = .active
            pairedIndex = mapID
        } else if unpaired {
            pairedIndex = fromIndex
        } else if abs(mapID - fromIndex) < abs(mapID - pairedIndex!) {
            pairedIndex = fromIndex
        } else if pairedIndex != fromIndex {
            return
        }

        set(mapRect)
    }

    func endUpdates() {
        userState = .idle
        beginActivityTimeout()
    }

    func isActive() -> Bool {
        return userState == .active
    }

    func unpair(from index: Int) {
        pairedIndex = pairedIndex == index ? nil : pairedIndex
    }


    // MARK: Helpers

    /// Sets the visble rect of self.mapView based on the current pairedIndex
    private func set(_ mapRect: MKMapRect) {
        mapView.setVisibleMapRect(mapRect, animated: false)
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
            delegate?.activityEnded(for: mapID)
        }
    }
}
