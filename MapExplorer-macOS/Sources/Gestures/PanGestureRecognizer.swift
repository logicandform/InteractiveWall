//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 20
        static let minimumFingers = 1
        static let minimumDeltaUpdateThreshold: Double = 4
        static let gesturePausedTime = 0.1
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) var state = GestureState.possible
    private(set) var delta = CGVector.zero
    private(set) var lastLocation: CGPoint?
    private var timeOfLastUpdate = Date()
    private var positionForTouch = [Touch: CGPoint]()
    private var cumulativeDelta = CGVector.zero


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .momentum, .failed:
            reset()
            fallthrough
        case .possible:
            momentumTimer?.invalidate()

            cumulativeDelta = .zero
            lastLocation = properties.cog

            state = .began
            gestureUpdated?(self)
            timeOfLastUpdate = Date()
            fallthrough
        case .recognized, .began:
            momentumTimer?.invalidate()
            positionForTouch[touch] = touch.position
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard state != .failed, let lastPositionOfTouch = positionForTouch[touch] else {
            return
        }

        positionForTouch[touch] = touch.position

        switch state {
        case .began:
            state = .recognized
            fallthrough
        case .recognized:
            recognizePanMove(with: touch, lastPosition: lastPositionOfTouch)

            if shouldUpdate(for: timeOfLastUpdate) {
                updateForMove(with: properties)
            }
        default:
            return
        }
    }

    /// Sets gesture properties during a move event and calls `gestureUpdated` callback
    private func updateForMove(with properties: TouchProperties) {
        delta = cumulativeDelta
        panMomentumDelta = delta
        cumulativeDelta = .zero

        gestureUpdated?(self)
        timeOfLastUpdate = Date()
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch.removeValue(forKey: touch)

        guard state != .failed, properties.touchCount.isZero else {
            return
        }

        let shouldStartMomentum = state == .recognized
        state = .ended
        gestureUpdated?(self)

        if shouldStartMomentum, abs(timeOfLastUpdate.timeIntervalSinceNow) < Constants.gesturePausedTime {
            beginMomentum()
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    func reset() {
        state = .possible
        positionForTouch.removeAll()
        lastLocation = nil
        delta = .zero
    }

    func invalidate() {
        momentumTimer?.invalidate()
        state = .failed
        gestureUpdated?(self)
    }


    // MARK: Helpers

    /// Updates pan properties during a move event when in the recognized state
    private func recognizePanMove(with touch: Touch, lastPosition: CGPoint) {
        guard let currentLocation = lastLocation else {
            return
        }

        positionForTouch[touch] = touch.position
        let offset = touch.position - lastPosition
        delta = offset.asVector / CGFloat(positionForTouch.keys.count)
        cumulativeDelta += delta
        lastLocation = currentLocation + delta
    }

    private func shouldUpdateForPan() -> Bool {
        return cumulativeDelta.magnitude > Constants.minimumDeltaUpdateThreshold
    }

    /// Returns true if enough time has passed to send send the next update
    private func shouldUpdate(for time: Date) -> Bool {
        return abs(time.timeIntervalSinceNow) > Configuration.refreshRate
    }


    // MARK: Momentum

    private struct Momentum {
        static let panInitialFrictionFactor = 1.04
        static let panFrictionFactorScale = 0.003
        static let panThresholdMomentumDelta: Double = 2
    }

    private var momentumTimer: Timer?
    private var panFrictionFactor = Momentum.panInitialFrictionFactor

    private var panMomentumDelta = CGVector.zero

    private func beginMomentum() {
        panFrictionFactor = Momentum.panInitialFrictionFactor
        delta = panMomentumDelta

        state = .momentum
        gestureUpdated?(self)
        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: Configuration.refreshRate, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        updatePanMomentum()

        if delta == .zero {
            endMomentum()
            return
        }

        gestureUpdated?(self)
    }

    private func updatePanMomentum() {
        if delta.magnitude < Momentum.panThresholdMomentumDelta {
            delta = .zero
        } else {
            panFrictionFactor += Momentum.panFrictionFactorScale
            delta /= panFrictionFactor
        }
    }

    private func endMomentum() {
        momentumTimer?.invalidate()
        reset()
        gestureUpdated?(self)
    }
}
