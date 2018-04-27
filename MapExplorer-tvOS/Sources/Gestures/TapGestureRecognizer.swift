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

    private var positionAndStartTimeForTouch = [Touch: (position: CGPoint, time: Date)]()


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        positionAndStartTimeForTouch[touch] = (touch.position, Date())
        removeExpiredTouches()

        position = touch.position
        state = .began

        // Dont update with began until startTapThresholdTime has passed
        Timer.scheduledTimer(withTimeInterval: Constants.startTapThresholdTime, repeats: false) { [weak self] _ in
            if let strongSelf = self, strongSelf.state == .began {
                strongSelf.gestureUpdated?(strongSelf)
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
            positionAndStartTimeForTouch.removeValue(forKey: touch)
            reset()
        } else {
            state = .ended
            checkForDoubleTap(with: touch)
            gestureUpdated?(self)
            reset()
        }
    }

    func reset() {
        state = .possible
    }


    // MARK: Helpers

    /// Removes the touch only after the time since it began is longer than double tap threshold, and it has ended
    private func removeExpiredTouches() {
        if state == .possible {
            positionAndStartTimeForTouch = positionAndStartTimeForTouch.filter { abs($0.value.time.timeIntervalSinceNow) < Constants.recognizeDoubleTapMaxTime }
        }
    }

    private func checkForDoubleTap(with touch: Touch) {
        for (initialPosition, time) in positionAndStartTimeForTouch.filter({ $0.key != touch }).values {
            if abs(time.timeIntervalSinceNow) < Constants.recognizeDoubleTapMaxTime && initialPosition.distance(to: touch.position) < Constants.recognizeDoubleTapMaxDistance {
                state = .doubleTapped
                return
            }
        }
    }
}
