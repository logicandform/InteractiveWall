//  Copyright © 2018 slant. All rights reserved.

import MapKit
import AppKit

class PlaceView: MKAnnotationView, SelectableView {
    static let identifier = "PlaceView"

    var didSelect: ((Place) -> Void)?

    override var annotation: MKAnnotation? {
        willSet {
            if let place = newValue as? Place {
                clusteringIdentifier = "place"
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
