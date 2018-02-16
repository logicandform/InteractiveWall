//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class TapGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let maximumDistanceMoved: CGFloat = 100
        static let minimumFingers = 1
    }

    var state = State.possible
    var initialPositions = [Int: CGPoint]()
    var fingers: Int

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch?, with properties: TouchProperties) {
        guard let touch = touch else {
            return
        }
        initialPositions[touch.id] = touch.position
        if state == .began {
            state = .failed
        } else if state == .possible && properties.touchCount == fingers {
            state = .began
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        if state == .began {
            guard let initialPoint = initialPositions[touch.id] else {
                return
            }

            let delta = CGVector(dx: initialPoint.x - touch.position.x, dy: initialPoint.y - touch.position.y)
            let distance = sqrt(delta.dx * delta.dx + delta.dy * delta.dy)
            if distance > Constants.maximumDistanceMoved {
                state = .failed
            }
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        if state == .began {
            gestureRecognized?(self)
            gestureUpdated?(self)
        }
        state = .possible
        initialPositions.removeValue(forKey: touch.id)
    }

    func reset() {
        state = .possible
        initialPositions.removeAll()
    }

    func invalidate() {
        state = .failed
    }
}
