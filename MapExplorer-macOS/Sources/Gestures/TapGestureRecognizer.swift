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
    var touchUpdated: ((GestureRecognizer, Touch) -> Void)?
    var position: CGPoint?
    private(set) var state = GestureState.possible

    private var positionForTouch = [Touch: CGPoint]()
    private var doubleTapPositionAndTimeForTouch = [Touch: (position: CGPoint, time: Date)]()
    private var delayTap: Bool
    private var cancelOnMove: Bool


    // MARK: Init
    init(withDelay: Bool = false, cancelsOnMove: Bool = true) {
        self.delayTap = withDelay
        self.cancelOnMove = cancelsOnMove
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch[touch] = touch.position
        doubleTapPositionAndTimeForTouch[touch] = (touch.position, Date())
        removeExpiredDoubleTapTouches()

        position = touch.position
        state = .began

        if !delayTap {
            gestureUpdated?(self)
            touchUpdated?(self, touch)
            state = .recognized
            return
        }

        // Dont update with began until startTapThresholdTime has passed
        Timer.scheduledTimer(withTimeInterval: Constants.startTapThresholdTime, repeats: false) { [weak self] _ in
            if let strongSelf = self, strongSelf.state == .began {
                strongSelf.gestureUpdated?(strongSelf)
                strongSelf.state = .recognized
            }
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
            if cancelOnMove {
                end(touch, with: properties)
            } else {
                touchUpdated?(self, touch)
                state = .recognized
            }
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        guard positionForTouch.keys.contains(touch) else {
            return
        }

        position = touch.position

        switch state {
        case .failed:
            gestureUpdated?(self)
            doubleTapPositionAndTimeForTouch.removeValue(forKey: touch)
        case .began:
            gestureUpdated?(self)
            fallthrough
        default:
            state = .ended
            checkForDoubleTap(with: touch)
            gestureUpdated?(self)
            touchUpdated?(self, touch)
        }

        reset()
        positionForTouch.removeValue(forKey: touch)
    }

    func reset() {
        state = .possible
    }


    // MARK: Helpers

    /// Removes touchs that have gone past the time to be recognized in a double tap
    private func removeExpiredDoubleTapTouches() {
        doubleTapPositionAndTimeForTouch = doubleTapPositionAndTimeForTouch.filter { abs($0.value.time.timeIntervalSinceNow) < Constants.recognizeDoubleTapMaxTime }
    }

    private func checkForDoubleTap(with touch: Touch) {
        for (initialPosition, time) in doubleTapPositionAndTimeForTouch.filter({ $0.key != touch }).values {
            if abs(time.timeIntervalSinceNow) < Constants.recognizeDoubleTapMaxTime && initialPosition.distance(to: touch.position) < Constants.recognizeDoubleTapMaxDistance {
                state = .doubleTapped
                return
            }
        }
    }
}
