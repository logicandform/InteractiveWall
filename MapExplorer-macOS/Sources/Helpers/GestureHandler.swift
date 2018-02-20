//  Copyright © 2018 JABT. All rights reserved.

import Foundation

class GestureHandler {

    private var touches = Set<Touch>()
    private var gestures: [GestureRecognizer]
    private var properties: TouchProperties {
        let c = centerOfGravity(for: touches)
        let (a, s) = angleAndSpread(of: touches)
        return TouchProperties(touchCount: touches.count, cog: c, angle: a, spread: s)
    }


    // MARK: Init

    init(gestures: [GestureRecognizer]) {
        self.gestures = gestures
    }


    // MARK: API

    func add(_ gesture: GestureRecognizer) {
        gestures.append(gesture)
    }

    func handle(_ touch: Touch) {
        switch touch.state {
        case .down:
            handleTouchDown(touch)
        case .up:
            handleTouchUp(touch)
        case .moved:
            handleTouchMoved(touch)
        }
    }

    func owns(_ touch: Touch) -> Bool {
        return touches.contains(touch)
    }


    // MARK: Helpers

    private func handleTouchDown(_ touch: Touch) {
        touches.insert(touch)
        gestures.forEach { $0.start(touch, with: properties) }
    }

    private func handleTouchMoved(_ touch: Touch) {
        if let match = touches.first(where: { $0 == touch }) {
            match.update(with: touch)
            gestures.forEach { $0.move(touch, with: properties) }
        }
    }

    private func handleTouchUp(_ touch: Touch) {
        touches.remove(touch)
        gestures.forEach { gesture in
            gesture.end(touch, with: properties)
        }
    }

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
