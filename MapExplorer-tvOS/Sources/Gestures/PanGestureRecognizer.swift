//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 100
        static let minimumFingers = 1
    }

    var state = State.possible
    var delta = CGVector.zero
    var lastPosition: CGPoint?
    var secondLastPosition: CGPoint?
    var thirdLastPosition: CGPoint?
    var fingers: Int

    var momentumTimer: Timer?

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
        } else if (state == .possible || state == .momentum) && properties.touchCount == fingers {
            state = .began
            momentumTimer?.invalidate()
            lastPosition = properties.cog
            secondLastPosition = lastPosition
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastPosition = lastPosition, let secondLastPosition = secondLastPosition else {
            return
        }

        switch state {
        case .began where abs(properties.cog.x - lastPosition.x) + abs(properties.cog.y - lastPosition.y) > Constants.recognizedThreshhold:
            gestureUpdated?(self)
            state = .recognized
            gestureRecognized?(self)
        case .recognized:
            delta = CGVector(dx: properties.cog.x - lastPosition.x, dy: properties.cog.y - lastPosition.y)
            thirdLastPosition = secondLastPosition
            self.secondLastPosition = lastPosition
            self.lastPosition = properties.cog
            gestureUpdated?(self)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        if properties.touchCount.isZero {
            guard let thirdLastPosition = thirdLastPosition, let lastPosition = lastPosition else {
                return
            }
            self.state = .momentum

            var difInPos = CGPoint(x: lastPosition.x - thirdLastPosition.x, y: lastPosition.y - thirdLastPosition.y)
            var factor: Double = 1

            momentumTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
                if(difInPos.magnitude() < 3) {
                    self.state = .possible
                    self.momentumTimer?.invalidate()
                }
                self.delta = CGVector(dx: difInPos.x, dy: difInPos.y)
                self.gestureUpdated?(self)
//                factor += 0.002
//                difInPos /= factor
            }
        } else {
            state = .failed
        }
        gestureUpdated?(self)
    }

    func reset() {
        lastPosition = nil
        delta = .zero
    }

    func invalidate() {
        state = .failed
    }
}
