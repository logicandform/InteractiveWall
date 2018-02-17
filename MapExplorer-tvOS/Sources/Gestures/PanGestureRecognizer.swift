//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 100
        static let minimumFingers = 1
        static let thresholdDelta: Double = 8
        static let frictionFactor = 1.05
        static let frictionFactorScale = 0.001
    }


    var state = State.possible
    var delta = CGVector.zero
    var fingers: Int
    var momentumTimer: Timer?
    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?

    // Leave this as an array for now for testing purposes, but more efficent to just store the past 3 positions
    var positions = [CGPoint?]()

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch?, with properties: TouchProperties) {
        if state == .began {
            state = .failed
        } else if (state == .possible || state == .momentum || touch == nil) && properties.touchCount == fingers {
            state = .began
            positions.append(properties.cog)
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard !positions.isEmpty, let lastPosition = positions[positions.count - 1] else {
            return
        }

        switch state {
        case .began where abs(properties.cog.x - lastPosition.x) + abs(properties.cog.y - lastPosition.y) > Constants.recognizedThreshhold:
            gestureUpdated?(self)
            state = .recognized
            gestureRecognized?(self)
        case .recognized:
            delta =  CGVector(dx: properties.cog.x - lastPosition.x, dy: properties.cog.y - lastPosition.y)
            positions.append(properties.cog)
            gestureUpdated?(self)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        if properties.touchCount.isZero {
            guard positions.count > 2, let lastPosition = positions[positions.count - 1], let secondLastPosition = positions[positions.count - 3]  else {
                return
            }
            self.state = .momentum

            var frictionFactor = Constants.frictionFactor

            delta = CGVector(dx: lastPosition.x - secondLastPosition.x, dy: lastPosition.y - secondLastPosition.y)
            delta *= Double(fingers)

            momentumTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
                if self.delta.magnitude() < Constants.thresholdDelta {
                    self.state = .possible
                    self.reset()
                    self.momentumTimer?.invalidate()
                }
                self.gestureUpdated?(self)
                frictionFactor += Constants.frictionFactorScale
                self.delta /= frictionFactor
            }
        } else {
            state = .failed
        }
    }

    func reset() {
        if state != .momentum {
            state = .possible
            positions.removeAll()
            delta = .zero
        }
    }

    func invalidate() {
        state = .failed
    }
}
