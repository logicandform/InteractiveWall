// Copyright © 2017 JABT Labs Inc. All rights reserved.

import Foundation
import MapKit

class MarkerView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            // 1
            guard let marker = newValue as? Marker else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            // 2
            markerTintColor = marker.markerTintColor
            if let imageName = marker.imageName {
                glyphImage = UIImage(named: imageName)
            }
            else{
                glyphText = String(marker.locationName.first!)
            }
        }
    }
}
