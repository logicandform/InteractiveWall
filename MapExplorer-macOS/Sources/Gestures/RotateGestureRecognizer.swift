//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class RotateGestureRecognizer: NSObject, GestureRecognizer {

    var state = GestureState.possible
    var startAngle: CGFloat = 0.0
    var lastAngle: CGFloat = 0.0
    var rotation: CGFloat = 0.0
    var scale: CGFloat = 1.0
    var fingers: Int

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?

    private struct Constants {
        static let thresh: CGFloat = .pi / 20
    }

    init(withFingers fingers: Int = 2) {
        precondition(fingers >= 2, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .began:
            state = .failed
        case .possible where properties.touchCount == fingers:
            state = .began
            startAngle = properties.angle
            lastAngle =  startAngle
            scale = 1.0
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .began where abs(properties.angle - startAngle) > Constants.thresh:
            state = .recognized
        case .recognized:
            rotation = properties.angle - lastAngle
            lastAngle = properties.angle
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
    }

    func reset() {
        state = .possible
    }
}
