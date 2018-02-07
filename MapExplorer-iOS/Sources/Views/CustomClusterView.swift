//  Copyright © 2018 JABT. All rights reserved.

import MapKit

class CustomClusterView: MKAnnotationView {
    static let identifier = "CustomClusterView"

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
                image = UIImage(named: "Cluster")
                canShowCallout = false
            }
        }
    }
}
