//  Copyright © 2018 slant. All rights reserved.

import MapKit
import AppKit

class PlaceView: MKAnnotationView, SelectableView {
    static let identifier = "PlaceView"

    weak var mapView: MKMapView?
    var didSelect: ((Place) -> Void)?

    override var annotation: MKAnnotation? {
        willSet {
            if let place = newValue as? Place {
                canShowCallout = true
                displayPriority = .defaultHigh
                image = NSImage(named: place.discipline.rawValue)
                rightCalloutAccessoryView = NSButton(title: "Show", target: self, action: #selector(didSelectView))
            }
        }
    }

    @objc
    func didSelectView() {
        if let place = annotation as? Place {
            didSelect?(place)
        }
    }
}
