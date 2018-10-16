//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MapKit


class CustomMapView: MKMapView {

    private var removedLegal = false

    override var isFlipped: Bool {
        return false
    }

    override func layout() {
        if !removedLegal {
            subviews.last?.removeFromSuperview()
            removedLegal = true
        }
        super.layout()
    }
}
