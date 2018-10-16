// Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit


class RecordAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    let record: Record

    init(coordinate: CLLocationCoordinate2D, record: Record) {
        self.coordinate = coordinate
        self.record = record
    }
}
