//  Copyright © 2018 slant. All rights reserved.

import Foundation
import CoreGraphics
import AppKit


extension CGFloat {

    var isZero: Bool {
        return self == 0
    }
}


extension CGRect {

    func transformed(from rect: CGRect) -> CGRect {
        return CGRect(origin: origin.transformed(from: rect), size: size)
    }
}


extension CGPoint {

    var asVector: CGVector {
        return CGVector(dx: x, dy: y)
    }

    private struct Keys {
        static let x = "x"
        static let y = "y"
    }

    init?(json: JSON) {
        guard let x = json[Keys.x] as? CGFloat, let y = json[Keys.y] as? CGFloat else {
            return nil
        }

        self.init()
        self.x = x
        self.y = y
    }

    func toJSON() -> JSON {
        return [Keys.x: x, Keys.y: y]
    }

    /// Subtracts the given view's origin from the point.
    func transformed(to view: NSView) -> CGPoint {
        return CGPoint(x: x - view.frame.minX, y: y - view.frame.minY)
    }

    /// Subtracts the given view's origin from the point.
    func transformed(to frame: CGRect) -> CGPoint {
        return CGPoint(x: x - frame.minX, y: y - frame.minY)
    }

    /// Adds the given view's origin from the point.
    func transformed(from frame: CGRect) -> CGPoint {
        return CGPoint(x: x + frame.minX, y: y + frame.minY)
    }

    /// Flips the coordinate system of the point in a given frame.
    func inverted(in frame: CGRect) -> CGPoint {
        return CGPoint(x: x, y: frame.size.height - y)
    }

    /// Gives the magnitude of the distance to a given point.
    func distance(to otherPoint: CGPoint) -> CGFloat {
        return sqrt(pow(x - otherPoint.x, 2) + pow(y - otherPoint.y, 2))
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    static func += (lhs: inout CGPoint, rhs: CGVector) {
        lhs.x += rhs.dx
        lhs.y += rhs.dy
    }

    static func -= (lhs: inout CGPoint, rhs: CGVector) {
        lhs.x -= rhs.dx
        lhs.y -= rhs.dy
    }

    static func += (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    static func -= (lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }

    static func += (lhs: inout CGPoint, rhs: CGFloat) {
        lhs.x += rhs
        lhs.y += rhs
    }

    static func -= (lhs: inout CGPoint, rhs: CGFloat) {
        lhs.x -= rhs
        lhs.y -= rhs
    }

    static func /= (lhs: inout CGPoint, rhs: Double) {
        lhs.x /= CGFloat(rhs)
        lhs.y /= CGFloat(rhs)
    }

    static func *= (lhs: inout CGPoint, rhs: Double) {
        lhs.x *= CGFloat(rhs)
        lhs.y *= CGFloat(rhs)
    }
}


extension CGVector {

    var asPoint: CGPoint {
        return CGPoint(x: dx, y: dy)
    }

    var magnitude: Double {
        return Double(sqrt(pow(self.dx, 2) + pow(self.dy, 2)))
    }

    func round() -> CGPoint {
        return CGPoint(x: self.dx.rounded(), y: self.dy.rounded())
    }

    static func * (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx * rhs.dx, dy: lhs.dy * rhs.dy)
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    static func / (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx / rhs, dy: lhs.dy / rhs)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func *= (lhs: inout CGVector, rhs: Double) {
        lhs.dx *= CGFloat(rhs)
        lhs.dy *= CGFloat(rhs)
    }

    static func /= (lhs: inout CGVector, rhs: Double) {
        lhs.dx /= CGFloat(rhs)
        lhs.dy /= CGFloat(rhs)
    }

    static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs.dx += rhs.dx
        lhs.dy += rhs.dy
    }
}


extension CGSize {

    static func + (lhs: inout CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func - (lhs: inout CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    static func *= (lhs: inout CGSize, rhs: CGFloat) {
        lhs.width *= rhs
        lhs.height *= rhs
    }

    static func /= (lhs: inout CGSize, rhs: CGFloat) {
        lhs.width /= rhs
        lhs.height /= rhs
    }

    static func += (lhs: inout CGSize, rhs: CGSize) {
        lhs.width += rhs.width
        lhs.height += rhs.height
    }

    static func += (lhs: inout CGSize, rhs: CGFloat) {
        lhs.width += rhs
        lhs.height += rhs
    }

    static func -= (lhs: inout CGSize, rhs: CGFloat) {
        lhs.width -= rhs
        lhs.height -= rhs
    }
}
