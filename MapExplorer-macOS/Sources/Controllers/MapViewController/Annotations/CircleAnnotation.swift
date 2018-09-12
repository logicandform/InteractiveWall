// Copyright © 2018 JABT. All rights reserved.


import Foundation
import MapKit


class CircleAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D
    var type: RecordType
    var title: String?

    init(coordinate: CLLocationCoordinate2D, type: RecordType, title: String) {
        self.coordinate = coordinate
        self.type = type
        self.title = title
    }
}
