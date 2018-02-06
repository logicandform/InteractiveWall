//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MapKit

class ClusterView: MKAnnotationView {

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
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
}
