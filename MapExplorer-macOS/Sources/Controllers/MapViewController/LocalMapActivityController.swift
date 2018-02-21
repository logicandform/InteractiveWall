//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit

class LocalMapActivityController: ActivityController {

    /// A collection of mapviews, indexed by their position, left -> right across windows
    private var mapViews = [MKMapView]()

    private var controllerForMapview = [MKMapView: MKMapView]()


    // MARK: API

    func resetMap() {
        
    }

    func beginSendingPosition() {

    }

    func stopSendingPosition() {

    }

    func add(_ maps: [MKMapView]) {
        mapViews.append(contentsOf: maps)
    }
}
