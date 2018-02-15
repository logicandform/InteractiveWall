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

extension CGVector {
    func size() -> Double {
        return Double(sqrt(pow(self.dx, 2) + pow(self.dy, 2)))
    }

    static func - (lhs: inout CGVector, rhs: CGVector) {
        lhs.x -= rhs.x
        lsh.y -= rhs.y
    }
}


