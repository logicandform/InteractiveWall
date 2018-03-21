// Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CircleAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
