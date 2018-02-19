//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit

extension MKMapRect: Equatable {

    static public func == (lhs: MKMapRect, rhs: MKMapRect) -> Bool {
        return lhs.origin == rhs.origin && lhs.size == rhs.size
    }
}

extension MKMapPoint: Equatable {

    static public func == (lhs: MKMapPoint, rhs: MKMapPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    static public func += (lhs: inout MKMapPoint, rhs: MKMapPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    static public func -= (lhs: inout MKMapPoint, rhs: MKMapPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }
}

extension MKMapSize: Equatable {

    static public func == (lhs: MKMapSize, rhs: MKMapSize) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }

    static public func += (lhs: inout MKMapSize, rhs: MKMapSize) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }

    static public func -= (lhs: inout MKMapSize, rhs: MKMapSize) {
        lhs.width -= rhs.width
        lhs.height -= rhs.height
    }

    static public func /= (lhs: inout MKMapSize, rhs: Double) {
        lhs.width /= rhs
        lhs.height /= rhs
    }
}

extension CLLocationCoordinate2D {

    // Example geolocation string: "Tofino [49.2761659,-126.0563673]"
    init?(geolocation: String?) {
        guard let location = geolocation, let openingBracket = location.index(of: "["), let comma = location.index(of: ","), let closingBracket = location.index(of: "]") else {
            return nil
        }

        let latitudeStart = location.index(after: openingBracket)
        let latitudeEnd = location.index(before: comma)
        let longitudeStart = location.index(after: comma)
        let longitudeEnd = location.index(before: closingBracket)

        guard let lat = Double(location[latitudeStart...latitudeEnd]), let long = Double(location[longitudeStart...longitudeEnd]) else {
            return nil
        }

        self.latitude = lat
        self.longitude = long
    }
}
