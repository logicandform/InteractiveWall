// Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CircleAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var record: RecordType


    init(coordinate: CLLocationCoordinate2D, record: RecordType) {
        self.coordinate = coordinate
        self.record = record
    }
}
