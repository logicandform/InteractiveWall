//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import AppKit
import MapKit

class FlippedMapView: MKMapView {
    fileprivate var removeLegal = true

    override var isFlipped: Bool {
        return true
    }

    override func layout() {
        if removeLegal {
            var subviews = self.subviews
            subviews.removeLast()
            subviews.last?.removeFromSuperview()
            removeLegal = true
        }
        super.layout()
    }
}
