//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit


/// Used to define the behavior of a PinchGestureRecognizer as its receiving move updates.
fileprivate enum PinchBehavior {
    case growing
    case shrinking
    case idle
}


class PinchGestureRecognizer: NSObject, GestureRecognizer {

    private struct Pinch {
        static let initialScale: CGFloat = 1
        static let numberOfFingers = 2
        static let minimumBehaviorChangeThreshold: CGFloat = 15
    }

    private struct Pan {
        static let recognizedThreshhold: CGFloat = 20
        static let minimumFingers = 1
        static let minimumDeltaUpdateThreshold: Double = 4
        static let updateTimeInterval: Double = 1 / 60
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) var state = GestureState.possible
    private(set) var scale: CGFloat = Pinch.initialScale
    private(set) var delta = CGVector.zero
    private(set) var locations = LastTwo<CGPoint>()

    // Pinch
    private var spreads = LastTwo<CGFloat>()
    private var lastSpreadSinceUpdate: CGFloat!
    private var behavior = PinchBehavior.idle
    private var currentSpread: CGFloat?
    private var touchesForSpread: (Touch, Touch)?

    // Pan
    private var positionForTouch = [Touch: CGPoint]()
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

            // Pinch
            spreads.add(properties.spread)

            // Pan
            cumulativeDelta = .zero
            locations.add(properties.cog)

            state = .began
            gestureUpdated?(self)
            timeOfLastUpdate = Date()
            fallthrough
        case .recognized, .began:
            momentumTimer?.invalidate()
            positionForTouch[touch] = touch.position
            lastTouchCount = positionForTouch.keys.count
            setTouchesForPinch()
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastSpread = spreads.last, let currentLocation = locations.last, let lastPositionOfTouch = positionForTouch[touch] else {
            return
        }

        positionForTouch[touch] = touch.position
        updateTouchesForSpread(with: touch)

        switch state {
        case .began:
            // Pinch
            if let touches = touchesForSpread {
                let touchSpread = spread(for: touches)
                behavior = behavior(of: touchSpread)
            }

            state = .recognized
            fallthrough
        case .recognized:
            var update = shouldUpdate(for: timeOfLastUpdate)

            // Pinch
            if let touches = touchesForSpread {
                let touchSpread = spread(for: touches)
                if shouldRecognize(touchSpread) {
                    scale = touchSpread / lastSpreadSinceUpdate
                    spreads.add(touchSpread)
                    lastSpreadSinceUpdate = touchSpread
                    update = true
                } else if changedBehavior(from: lastSpread, to: touchSpread) {
                    scale = Pinch.initialScale
                    behavior = behavior(of: touchSpread)
                    spreads.add(touchSpread)
                    lastSpreadSinceUpdate = touchSpread
                    update = true
                }
            }

            // Pan
            lastTouchCount = positionForTouch.keys.count
            positionForTouch[touch] = touch.position
            let offset = touch.position - lastPositionOfTouch
            delta = offset.asVector / CGFloat(lastTouchCount)
            cumulativeDelta += delta
            locations.add(currentLocation + delta)
            update = update || shouldUpdateForPan()

            if update {
                // Pan
                delta = cumulativeDelta
                cumulativeDelta = .zero

                gestureUpdated?(self)
                timeOfLastUpdate = Date()
            }
        default:
            return
        }
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
            let velocity = panVelocity ?? .zero
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
        spreads.clear()
        scale = Pinch.initialScale
        behavior = .idle

        // Pan
        positionForTouch.removeAll()
        locations.clear()
        delta = .zero
    }


    // MARK: Pinch Helpers

    /// Returns the behavior of the spread based off the current last spread.
    private func behavior(of spread: CGFloat) -> PinchBehavior {
        guard let lastSpread = spreads.last else {
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
        guard positionForTouch.keys.count == Pinch.numberOfFingers else {
            touchesForSpread = nil
            scale = Pinch.initialScale
            behavior = .idle
            return
        }

        let touches = positionForTouch.keys.sorted(by: { $0.id < $1.id })
        let first = touches.first!
        let last = touches.last!
        touchesForSpread = (first, last)
        let touchSpread = spread(for: (first, last))
        lastSpreadSinceUpdate = touchSpread
        behavior = .idle
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

    /// If the newSpread has a different behavior and surpasses the minimum threshold, returns true
    private func changedBehavior(from oldSpread: CGFloat, to newSpread: CGFloat) -> Bool {
        if behavior != behavior(of: newSpread), abs(oldSpread - newSpread) > Pinch.minimumBehaviorChangeThreshold {
            return true
        }

        return false
    }


    // MARK: Pan Helpers

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
        static let panInitialFrictionFactor = 1.05
        static let panFrictionFactorScale = 0.001
        static let panThresholdMomentumDelta: Double = 2
    }

    private var momentumTimer: Timer?
    private var panFrictionFactor = Momentum.panInitialFrictionFactor
    private var pinchFrictionFactor = Momentum.pinchInitialFrictionFactor

    private var panVelocity: CGVector? {
        guard let last = locations.last, let secondLast = locations.secondLast else { return nil }
        return CGVector(dx: last.x - secondLast.x, dy: last.y - secondLast.y)
    }

    private var pinchScale: CGFloat? {
        guard let last = spreads.last, let secondLast = spreads.secondLast else { return nil }
        let momentumScale = last / secondLast
        return followsBehavior(scale: momentumScale) ? momentumScale : Pinch.initialScale
    }

    private func beginMomentum(_ velocity: CGVector, _ scale: CGFloat) {
        // Pinch
        pinchFrictionFactor = Momentum.pinchInitialFrictionFactor
        self.scale = scale

        // Pan
        panFrictionFactor = Momentum.panInitialFrictionFactor
        delta = velocity * CGFloat(lastTouchCount)

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
