//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MapKit

class FlippedMapView: MKMapView {
    fileprivate var removeLegal = true

    override var isFlipped: Bool {
        return false
    }

    override func layout() {
        if removeLegal {
            self.subviews.last?.removeFromSuperview()
            removeLegal = true
        }
        super.layout()
    }
}
