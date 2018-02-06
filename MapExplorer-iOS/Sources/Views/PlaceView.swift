//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import UIKit

class PlaceView: MKAnnotationView {

    override var annotation: MKAnnotation? {
        willSet {
            if let place = newValue as? Place {
                clusteringIdentifier = "place"
                image = UIImage(named: place.discipline.rawValue)
                displayPriority = .defaultHigh
            }
        }
    }
}
