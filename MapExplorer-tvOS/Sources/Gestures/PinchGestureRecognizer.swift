//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PinchGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let initialScale: CGFloat = 1.0
        static let minimumFingers = 2
        static let minimumSpreadThreshhold: CGFloat = 0.1
    }

    var state = NSGestureRecognizer.State.possible
    var lastSpread: CGFloat!
    var lastPosition: CGPoint!
    var scale: CGFloat = Constants.initialScale
    var fingers: Int
    var delta = CGVector.zero


    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .began:
            state = .failed
        case .possible where properties.touchCount == fingers:
            state = .began
            lastSpread = properties.spread
            lastPosition = properties.cog
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastSpread = lastSpread, let lastPosition = lastPosition else {
            return
        }

        switch state {
        case .began where abs(properties.spread / lastSpread - 1.0) > Constants.minimumSpreadThreshhold:
            gestureUpdated?(self)
            state = .recognized
            gestureRecognized?(self)
        case .recognized:
            scale = properties.spread / lastSpread
            delta = CGVector(dx: properties.cog.x - lastPosition.x, dy: properties.cog.y - lastPosition.y)
            self.lastSpread = properties.spread
            self.lastPosition = properties.cog
            gestureUpdated?(self)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        if properties.touchCount.isZero {
            state = .possible
        } else {
            state = .failed
        }
        gestureUpdated?(self)
    }

    func reset() {
        state = .possible
        scale = Constants.initialScale
        lastSpread = nil
        lastPosition = nil
    }

    func invalidate() {
        state = .failed
    }
}
