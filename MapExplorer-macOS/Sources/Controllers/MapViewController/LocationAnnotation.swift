//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import AppKit

class LocationAnnotation: NSObject, MKAnnotation {

    let item: LocationItem

    init(item: LocationItem) {
        self.item = item
    }

    var coordinate: CLLocationCoordinate2D {
        return item.coordinate
    }

    var title: String? {
        return item.title
    }

    var color: NSColor {
        return item.discipline.color
    }
}
