//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class TapGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let maximumDistanceMoved: CGFloat = 20
        static let minimumFingers = 1
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var position: CGPoint?
    private(set) var state = GestureState.possible
    private(set) var fingers: Int

    private var positionForTouch = [Touch: CGPoint]()


    // MARK: Init

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch[touch] = touch.position

        if properties.touchCount == fingers {
            position = touch.position
            state = .began
            gestureUpdated?(self)
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let initialPosition = positionForTouch[touch] else {
            return
        }

        let delta = CGVector(dx: initialPosition.x - touch.position.x, dy: initialPosition.y - touch.position.y)
        let distance = sqrt(pow(delta.dx, 2) + pow(delta.dy, 2))
        if distance > Constants.maximumDistanceMoved {
            state = .failed
            end(touch, with: properties)
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        guard positionForTouch.keys.contains(touch) else {
            return
        }

        position = touch.position

        if state == .failed {
            gestureUpdated?(self)
            reset()
        } else if properties.touchCount.isZero {
            state = .ended
            gestureUpdated?(self)
            reset()
        } else {
            positionForTouch.removeValue(forKey: touch)
        }
    }

    func reset() {
        positionForTouch.removeAll()
        state = .possible
    }
}

