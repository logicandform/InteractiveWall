//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class LongTapGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let maximumDistanceMoved: CGFloat = 20
        static let minimumFingers = 1
        static let startTapThresholdTime = 0.15
        static let recognizeDoubleTapMaxTime = 0.5
        static let recognizeDoubleTapMaxDistance: CGFloat = 40
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var longTapUpdate: ((GestureRecognizer, CGPoint) -> Void)?
    var position: CGPoint?
    private(set) var state = GestureState.possible

    private var positionForTouch = [Touch: CGPoint]()
    private var doubleTapPositionAndTimeForTouch = [Touch: (position: CGPoint, time: Date)]()
    private var delayTap: Bool


    // MARK: Init
    init(withDelay: Bool = false) {
        self.delayTap = withDelay
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch[touch] = touch.position
        doubleTapPositionAndTimeForTouch[touch] = (touch.position, Date())
        removeExpiredDoubleTapTouches()

        position = touch.position
        state = .began

        if !delayTap {
//            gestureUpdated?(self)
            longTapUpdate?(self, touch.position)
            state = .recognized
            return
        }

        // Dont update with began until startTapThresholdTime has passed
        Timer.scheduledTimer(withTimeInterval: Constants.startTapThresholdTime, repeats: false) { [weak self] _ in
            if let strongSelf = self, strongSelf.state == .began {
//                strongSelf.gestureUpdated?(strongSelf)
                strongSelf.state = .recognized
            }
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        return
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        guard let initialPosition = positionForTouch[touch] else {
            return
        }

        position = touch.position

        switch state {
        case .failed:
//            gestureUpdated?(self)
            doubleTapPositionAndTimeForTouch.removeValue(forKey: touch)
            fallthrough
        case .began:
//            gestureUpdated?(self)
            fallthrough
        default:
            state = .ended
            checkForDoubleTap(with: touch)
//            gestureUpdated?(self)
            longTapUpdate?(self, CGPoint(x: touch.position.x, y: initialPosition.y))
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
