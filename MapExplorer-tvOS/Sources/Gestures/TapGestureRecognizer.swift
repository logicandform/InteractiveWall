//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class TapGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let maximumDistanceMoved: CGFloat = 100
        static let minimumFingers = 1
    }

    var fingers: Int
    private var positionForTouch = [Touch: CGPoint]()
    var position: CGPoint?


    var gestureUpdated: ((GestureRecognizer) -> Void)?

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        guard !positionForTouch.keys.contains(touch) else {
            return
        }

        positionForTouch[touch] = touch.position
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let initialPosition = positionForTouch[touch] else {
            return
        }

        let delta = CGVector(dx: initialPosition.x - touch.position.x, dy: initialPosition.y - touch.position.y)
        let distance = sqrt(pow(delta.dx, 2) + pow(delta.dy, 2))
        if distance > Constants.maximumDistanceMoved {
            positionForTouch.removeValue(forKey: touch)
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        guard positionForTouch.keys.contains(touch) else {
            return
        }

        position = touch.position

        gestureUpdated?(self)
        if properties.touchCount.isZero {
           reset()
        } else {
            positionForTouch.removeValue(forKey: touch)
        }
    }

    func reset() {
         positionForTouch.removeAll()
    }
}
