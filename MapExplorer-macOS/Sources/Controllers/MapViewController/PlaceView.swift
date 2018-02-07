//  Copyright © 2018 slant. All rights reserved.

import MapKit
import AppKit

class PlaceView: MKAnnotationView {
    static let identifier = "PlaceView"

    override var annotation: MKAnnotation? {
        willSet {
            if let place = newValue as? Place {
                clusteringIdentifier = "place"
                displayPriority = .defaultHigh
                image = NSImage(named: place.discipline.rawValue)
            }
        }
    }
}
