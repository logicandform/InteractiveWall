//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class TapGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let maximumDistanceMoved: CGFloat = 20
        static let minimumFingers = 1
        static let startTapThresholdTime = 0.15
        static let recognizeDoubleTapMaxTime = 0.5
        static let recognizeDoubleTapMaxDistance: CGFloat = 40
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var position: CGPoint?
    private(set) var state = GestureState.possible
    private(set) var fingers: Int
    private(set) var doubleTapped = false

    private var positionAndStartTimeForTouch = [Touch: (position: CGPoint, time: Date)]()


    // MARK: Init

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.fingers = fingers
        super.init()
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        positionAndStartTimeForTouch[touch] = (touch.position, Date())

        if properties.touchCount == fingers {
            position = touch.position
            state = .began

            Timer.scheduledTimer(withTimeInterval: Constants.startTapThresholdTime, repeats: false) { [weak self] _ in
                if let strongSelf = self {
                    strongSelf.gestureUpdated?(strongSelf)
                }
            }
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let initialPosition = positionAndStartTimeForTouch[touch]?.position else {
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
        guard positionAndStartTimeForTouch.keys.contains(touch) else {
            return
        }

        position = touch.position

        if state == .failed {
            gestureUpdated?(self)
            reset()
        } else if properties.touchCount.isZero {
            checkForDoubleTap(with: touch)
            state = .ended
            gestureUpdated?(self)
            reset()
        }

        remove(touch)
    }

    func reset() {
        state = .possible
        doubleTapped = false
    }


    // MARK: Helpers

    /// Removes the touch only after the time since it began is longer than double tap threshold
    private func remove(_ touch: Touch) {
        guard let time = positionAndStartTimeForTouch[touch]?.time else {
            return
        }

        let timeInterval = Constants.recognizeDoubleTapMaxTime - abs(time.timeIntervalSinceNow)
        if timeInterval.sign == .minus {
            positionAndStartTimeForTouch.removeValue(forKey: touch)
        } else {
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                self?.positionAndStartTimeForTouch.removeValue(forKey: touch)
            }
        }
    }

    private func checkForDoubleTap(with touch: Touch) {
        for (initialPosition, time) in positionAndStartTimeForTouch.filter({ $0.key != touch }).values {
            if abs(time.timeIntervalSinceNow) < Constants.recognizeDoubleTapMaxTime && initialPosition.distance(to: touch.position) < Constants.recognizeDoubleTapMaxDistance {
                doubleTapped = true
                return
            }
        }
    }
}
