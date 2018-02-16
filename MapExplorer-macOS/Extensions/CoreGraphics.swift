//  Copyright © 2018 slant. All rights reserved.

import Foundation
import CoreGraphics

extension CGPoint {

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
    static func *= (lhs: inout CGVector, rhs: Double) {
        lhs.dx *= CGFloat(rhs)
        lhs.dy *= CGFloat(rhs)
    }

    static func /= (lhs: inout CGVector, rhs: Double) {
        lhs.dx /= CGFloat(rhs)
        lhs.dy /= CGFloat(rhs)
    }

    func magnitude() -> Double {
        return Double(sqrt(pow(self.dx, 2) + pow(self.dy, 2)))
    }
}

extension CGSize {

    static func *= (lhs: inout CGSize, rhs: CGFloat) {
        lhs.width *= rhs
        lhs.height *= rhs
    }

    static func /= (lhs: inout CGSize, rhs: CGFloat) {
        lhs.width /= rhs
        lhs.height /= rhs
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
