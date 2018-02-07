//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit

class ClusterView: MKAnnotationView {
    static let identifier = "ClusterView"

    var didTapCallout: ((MKClusterAnnotation)->())?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
        canShowCallout = true
        rightCalloutAccessoryView = NSButton(title: "More", target: self, action: #selector(calloutButtonSelected))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var annotation: MKAnnotation? {
        willSet {
            if let _ = newValue as? MKClusterAnnotation {
                image = NSImage(named: "Cluster")
            }
        }
    }

    @objc
    private func calloutButtonSelected() {
        if let cluster = annotation as? MKClusterAnnotation {
            didTapCallout?(cluster)
        }
    }
}
