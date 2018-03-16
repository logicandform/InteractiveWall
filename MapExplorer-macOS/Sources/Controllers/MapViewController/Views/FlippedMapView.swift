//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MapKit

class FlippedMapView: MKMapView {
    override var isFlipped: Bool {
        return false
    }
}
