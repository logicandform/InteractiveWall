//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit


/// Used to define the behavior of a PinchGestureRecognizer as its receiving move updates.
fileprivate enum PinchBehavior: String {
    case growing
    case shrinking
    case idle
}


class PinchGestureRecognizer: NSObject, GestureRecognizer {

    private struct Pinch {
        static let initialScale: CGFloat = 1
        static let numberOfFingers = 2
        static let minimumBehaviorChangeThreshold: CGFloat = 20
        static let minimumSpreadDistance: CGFloat = 60
    }

    private struct Pan {
        static let recognizedThreshhold: CGFloat = 20
        static let minimumFingers = 1
        static let minimumDeltaUpdateThreshold: Double = 4
        static let updateTimeInterval = Configuration.refreshRate
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) var state = GestureState.possible
    private(set) var scale: CGFloat = Pinch.initialScale
    private(set) var delta = CGVector.zero
    private(set) var center: CGPoint!

    // Pinch
    private(set) var lastSpread: CGFloat?
    private var lastSpreadSinceUpdate: CGFloat!
    private var behavior = PinchBehavior.idle
    private var touchesForSpread: (Touch, Touch)?

    // Pan
    private var positionForTouch = [Touch: CGPoint]()
    private var lastLocation: CGPoint?
    private var cumulativeDelta = CGVector.zero
    private var lastTouchCount: Int!
    private var timeOfLastUpdate: Date!


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .momentum:
            reset()
            fallthrough
        case .possible:
            momentumTimer?.invalidate()

            // Pan
            cumulativeDelta = .zero
            lastLocation = properties.cog

            state = .began
            gestureUpdated?(self)
            timeOfLastUpdate = Date()
            fallthrough
        case .recognized, .began:
            momentumTimer?.invalidate()

            // Pan
            positionForTouch[touch] = touch.position
            lastTouchCount = positionForTouch.keys.count

            // Pinch
            center = properties.cog
            // Must come after postionForTouch is set
            setTouchesForPinch()
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastPositionOfTouch = positionForTouch[touch] else {
            return
        }

        positionForTouch[touch] = touch.position
        updateTouchesForSpread(with: touch)
        lastTouchCount = positionForTouch.keys.count

        switch state {
        case .began:
            beganPinchMove()
            state = .recognized
            fallthrough
        case .recognized:
            recognizePinchMove()
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
        // Pinch
        center = properties.cog

        // Pan
        delta = cumulativeDelta
        cumulativeDelta = .zero

        gestureUpdated?(self)
        if let touches = touchesForSpread {
            let touchSpread = spread(for: touches)
            lastSpreadSinceUpdate = touchSpread
        }
        timeOfLastUpdate = Date()
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch.removeValue(forKey: touch)
        setTouchesForPinch()

        guard properties.touchCount.isZero else {
            return
        }

        let shouldStartMomentum = state == .recognized
        state = .ended
        gestureUpdated?(self)

        if shouldStartMomentum {
            let velocity = touch.velocity ?? .zero
            let scale = pinchScale ?? Pinch.initialScale
            beginMomentum(velocity, scale)
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    func reset() {
        state = .possible

        // Pinch
        lastSpread = nil
        scale = Pinch.initialScale
        behavior = .idle
        center = nil

        // Pan
        positionForTouch.removeAll()
        lastLocation = nil
        delta = .zero
    }


    // MARK: Pinch Helpers

    /// Updates pinch properties during a move event when in the began state
    private func beganPinchMove() {
        if let touches = touchesForSpread {
            let touchSpread = spread(for: touches)
            behavior = behavior(of: touchSpread)
        }
    }

    /// Updates pinch properties during a move event when in the recognized state
    private func recognizePinchMove() {
        guard let touches = touchesForSpread else {
            return
        }

        let touchSpread = spread(for: touches)
        let lastSpread = self.lastSpread ?? touchSpread

        if shouldRecognize(touchSpread), touchSpread > Pinch.minimumSpreadDistance {
            scale = touchSpread / lastSpreadSinceUpdate
            behavior = behavior(of: touchSpread)
            self.lastSpread = touchSpread
        } else if changedBehavior(from: lastSpread, to: touchSpread), touchSpread > Pinch.minimumSpreadDistance {
            scale = Pinch.initialScale
            behavior = behavior(of: touchSpread)
            self.lastSpread = touchSpread
        } else {
            scale = Pinch.initialScale
        }
    }

    /// Returns the behavior of the spread based off the current last spread.
    private func behavior(of spread: CGFloat) -> PinchBehavior {
        guard let lastSpread = lastSpread else {
            return .idle
        }

        return (spread - lastSpread > 0) ? .growing : .shrinking
    }

    /// Returns true if the given spread is of the same behavior type, or the current behavior is idle
    private func shouldRecognize(_ spread: CGFloat) -> Bool {
        return behavior == behavior(of: spread) || behavior == .idle
    }

    private func followsBehavior(scale: CGFloat) -> Bool {
        return (scale > 1 && behavior == .growing) || (scale < 1 && behavior == .shrinking)
    }

    private func setTouchesForPinch() {
        guard lastTouchCount == Pinch.numberOfFingers else {
            touchesForSpread = nil
            scale = Pinch.initialScale
            return
        }

        let touches = positionForTouch.keys.sorted(by: { $0.id < $1.id })
        let first = touches.first!
        let last = touches.last!
        let touchSpread = spread(for: (first, last))
        touchesForSpread = (first, last)
        lastSpreadSinceUpdate = touchSpread
    }

    private func updateTouchesForSpread(with touch: Touch) {
        if let touches = touchesForSpread {
            if touches.0 == touch {
                touches.0.update(with: touch)
            } else if touches.1 == touch {
                touches.1.update(with: touch)
            }
        }
    }

    private func spread(for touches: (first: Touch, second: Touch)) -> CGFloat {
        return sqrt(pow(touches.first.position.x - touches.second.position.x, 2) + pow(touches.first.position.y - touches.second.position.y, 2))
    }

    private func spread(for positions: (first: CGPoint, second: CGPoint)) -> CGFloat {
        return sqrt(pow(positions.first.x - positions.second.x, 2) + pow(positions.first.y - positions.second.y, 2))
    }

    /// If the newSpread has a different behavior and surpasses the minimum threshold, returns true
    private func changedBehavior(from oldSpread: CGFloat, to newSpread: CGFloat) -> Bool {
        if behavior != behavior(of: newSpread), abs(oldSpread - newSpread) > Pinch.minimumBehaviorChangeThreshold {
            return true
        }

        return false
    }


    // MARK: Pan Helpers

    /// Updates pan properties during a move event when in the recognized state
    private func recognizePanMove(with touch: Touch, lastPosition: CGPoint) {
        guard let currentLocation = lastLocation else {
            return
        }

        positionForTouch[touch] = touch.position
        let offset = touch.position - lastPosition
        delta = offset.asVector / CGFloat(lastTouchCount)
        cumulativeDelta += delta
        lastLocation = currentLocation + delta
    }

    private func shouldUpdateForPan() -> Bool {
        return cumulativeDelta.magnitude > Pan.minimumDeltaUpdateThreshold
    }

    /// Returns true if enough time has passed to send send the next update
    private func shouldUpdate(for time: Date) -> Bool {
        return abs(time.timeIntervalSinceNow) > Pan.updateTimeInterval
    }


    // MARK: Momentum

    private struct Momentum {
        static let pinchThresholdMomentumScale: CGFloat = 0.0001
        static let pinchInitialFrictionFactor: CGFloat = 1.04
        static let pinchFrictionFactorScale: CGFloat = 0.002
        static let panInitialFrictionFactor = 1.01
        static let panFrictionFactorScale = 0.001
        static let panThresholdMomentumDelta: Double = 2
    }

    private var momentumTimer: Timer?
    private var panFrictionFactor = Momentum.panInitialFrictionFactor
    private var pinchFrictionFactor = Momentum.pinchInitialFrictionFactor

    private var pinchScale: CGFloat? {
        guard let touches = touchesForSpread, let velocity0 = touches.0.velocity, let velocity1 = touches.1.velocity else {
            return nil
        }
        let lastSpread = spread(for: (touches.0, touches.1))

        let position0 = touches.0.position + velocity0 * CGFloat(Configuration.refreshRate)
        let position1 = touches.1.position + velocity1 * CGFloat(Configuration.refreshRate)
        let newSpreadFromVelocity = spread(for: (position0, position1))

        return newSpreadFromVelocity / lastSpread
    }


    private func beginMomentum(_ velocity: CGVector, _ scale: CGFloat) {
        // Pinch
        pinchFrictionFactor = Momentum.pinchInitialFrictionFactor
        self.scale = scale

        // Pan
        panFrictionFactor = Momentum.panInitialFrictionFactor
        delta = velocity

        state = .momentum
        gestureUpdated?(self)
        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: Pan.updateTimeInterval, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        updatePinchMomentum()
        updatePanMomentum()

        if delta == .zero && scale == Pinch.initialScale {
            endMomentum()
            return
        }

        gestureUpdated?(self)
    }

    private func updatePinchMomentum() {
        if abs(scale - 1) < Momentum.pinchThresholdMomentumScale {
            scale = Pinch.initialScale
        } else {
            scale -= 1
            scale /= pinchFrictionFactor
            scale += 1
            pinchFrictionFactor += Momentum.pinchFrictionFactorScale
        }
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
