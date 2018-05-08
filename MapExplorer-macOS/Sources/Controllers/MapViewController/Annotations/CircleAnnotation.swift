// Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit

class CircleAnnotation: NSObject, MKAnnotation {

    dynamic var coordinate: CLLocationCoordinate2D
    var record: RecordType
    var title: String?

    init(coordinate: CLLocationCoordinate2D, record: RecordType, title: String) {
        self.coordinate = coordinate
        self.record = record
        self.title = title
    }
}
