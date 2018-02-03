//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit

class CircleAnnotationView: MKAnnotationView {
    static let identifier = "CircleAnnotationView"

    private struct Constants {
        static let calloutOffset = CGPoint(x: 0, y: -10)
        static let circleRadius: CGFloat = 10
    }

    let circle = UIView(frame: CGRect(origin: CGPoint(x: -10, y: -10), size: CGSize(width: 20, height: 20)))

    override var annotation: MKAnnotation? {
        willSet {
            guard let annotation = newValue as? LocationAnnotation else {
                return
            }
            clusteringIdentifier = CircleAnnotationView.identifier
            circle.backgroundColor = annotation.item.discipline.color
            circle.layer.cornerRadius = Constants.circleRadius
            circle.clipsToBounds = true
            addSubview(circle)
        }
    }
}
