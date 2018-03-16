//  Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class LocationOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect

    init(coordinate: CLLocationCoordinate2D, mapRect: MKMapRect) {
        self.coordinate = coordinate
        self.boundingMapRect = mapRect
    }
}
