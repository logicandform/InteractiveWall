//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import UIKit
import C4


class GestureHandler: NSObject {

    private(set) var touches = Set<Touch>()
    private(set) var gestures = [GestureRecognizer]()

    private var properties: TouchProperties {
        let c = centerOfGravity(for: touches)
        let (a, s) = angleAndSpread(of: touches)
        return TouchProperties(touchCount: touches.count, cog: c, angle: a, spread: s)
    }


    // MARK: API

    func handle(_ touch: Touch) {
        switch touch.state {
        case .down:
            touches.insert(touch)
            gestures.forEach { $0.start(touch, with: properties) }
        case .up:
            touches.remove(touch)
            gestures.forEach { gesture in
                gesture.end(touch, with: properties)
                if touches.isEmpty {
                    gesture.reset()
                }
            }
        case .moved:
            if let match = touches.first(where: { $0 == touch }) {
                match.update(with: touch)
                gestures.forEach { $0.move(touch, with: properties) }
            }
        }
    }

    func add(_ gesture: GestureRecognizer) {
        gesture.gestureRecognized = gestureRecognized(_:)
        gestures.append(gesture)
    }

    func gestureRecognized(_ gesture: GestureRecognizer) {
        for each in gestures where each !== gesture {
            if type(of: each) == type(of: gesture) {
                each.invalidate()
            }
        }
    }


    // MARK: Helpers

    /// Calculate the center of gravity of the touches involved
    private func centerOfGravity(for touches: Set<Touch>) -> CGPoint {
        var x: CGFloat = 0
        var y: CGFloat = 0
        for touch in touches {
            x += touch.position.x
            y += touch.position.y
        }
        x /= CGFloat(touches.count)
        y /= CGFloat(touches.count)
        return CGPoint(x: x, y: y)
    }

    /// Calculate the angle and spread of the touches involved
    private func angleAndSpread(of touches: Set<Touch>) -> (angle: CGFloat, spread: CGFloat) {
        guard touches.count > 1 else {
            return (0, 0)
        }

        let cog = centerOfGravity(for: touches)
        let xDist = touches.first!.position.x - cog.x
        let yDist = touches.first!.position.y - cog.y
        return (atan2(yDist, xDist), CGFloat(sqrt((xDist * xDist) + (yDist * yDist))))
    }
}
