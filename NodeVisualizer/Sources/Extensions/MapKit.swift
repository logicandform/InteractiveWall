//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit

extension MKMapRect: Equatable {

    private struct Keys {
        static let x = "x"
        static let y = "y"
        static let width = "width"
        static let height = "height"
    }

    init?(json: JSON) {
        self.init()
        guard let x = json[Keys.x] as? Double, let y = json[Keys.y] as? Double, let width = json[Keys.width] as? Double, let height = json[Keys.height] as? Double else {
            return nil
        }

        self.origin = MKMapPoint(x: x, y: y)
        self.size = MKMapSize(width: width, height: height)
    }

    func toJSON() -> JSON {
        return [Keys.x: origin.x, Keys.y: origin.y, Keys.width: size.width, Keys.height: size.height]
    }

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
