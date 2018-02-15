//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 100
        static let minimumFingers = 1
        static let velocityThreshold = Double(1)
    }

    var state = NSGestureRecognizer.State.possible
    var delta = CGVector.zero
    var lastPosition: CGPoint?
    var lastPositionTime: Date!
    var time: CGFloat!
    var velocity: CGVector!
    var fingers: Int

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        if state == .began {
            state = .failed
        } else if state == .possible && properties.touchCount == fingers {
            state = .began
            lastPosition = properties.cog
            lastPositionTime = Date()
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastPosition = lastPosition else {
            return
        }

        switch state {
        case .began where abs(properties.cog.x - lastPosition.x) + abs(properties.cog.y - lastPosition.y) > Constants.recognizedThreshhold:
            gestureUpdated?(self)
            state = .recognized
            gestureRecognized?(self)
        case .recognized:
            time = CGFloat(-lastPositionTime.timeIntervalSinceNow)
            lastPositionTime = Date()
            delta = CGVector(dx: properties.cog.x - lastPosition.x, dy: properties.cog.y - lastPosition.y)
            //velocity = CGVector(dx: delta.dx / time, dy: delta.dy / time)
            velocity = CGVector(dx: 100, dy: 0)

           // print(velocity)
            self.lastPosition = properties.cog
            gestureUpdated?(self)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        if properties.touchCount.isZero {
            guard let lastPosition = lastPosition else {
                return
            }

            while(velocity.size() > Constants.velocityThreshold) {
                delta = CGVector(dx: lastPosition.x - velocity.dx, dy:lastPosition.y - velocity.dy)

                gestureUpdated?(self)
            }


            state = .possible
        } else {
            state = .failed
        }
        gestureUpdated?(self)
    }

    func reset() {
        state = .possible
        lastPosition = nil
        delta = .zero
    }

    func invalidate() {
        state = .failed
    }
}
