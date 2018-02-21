//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit

class ClusterView: MKAnnotationView, SelectableView {
    static let identifier = "ClusterView"

    weak var mapView: MKMapView?
    var didSelect: ((MKClusterAnnotation, MKMapView) -> Void)?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
        canShowCallout = true
        rightCalloutAccessoryView = NSButton(title: "More", target: self, action: #selector(didSelectView))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var annotation: MKAnnotation? {
        willSet {
            if newValue as? MKClusterAnnotation != nil {
                image = NSImage(named: "Cluster")
            }
        }
    }

    @objc
    func didSelectView() {
        if let cluster = annotation as? MKClusterAnnotation, let mapView = mapView {
            didSelect?(cluster, mapView)
        }
    }
}
