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
