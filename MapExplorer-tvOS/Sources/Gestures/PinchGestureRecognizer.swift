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

    private struct Constants {
        static let initialScale: CGFloat = 1
        static let minimumFingers = 2
        static let updateTimeInterval: Double = 1 / 60
        static let minimumDeltaUpdateThreshold: Double = 4
        static let fromIdleBehaviorChangeThreshold: CGFloat = 20
        static let toIdleBehaviorChangeThreshold: CGFloat = 10
        static let cancelPanMomentumCounterThreshold = 20
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) var lastPosition: CGPoint!
    private(set) var state = GestureState.possible
    private(set) var scale: CGFloat = Constants.initialScale
    private(set) var delta = CGVector.zero
    private(set) var locations = LastTwo<CGPoint>()
    private let fingers: Int
    private var timeOfLastUpdate: Date!
    private var spreads = LastTwo<CGFloat>()
    private var lastSpreadSinceUpdate: CGFloat!
    private var positionForTouch = [Touch: CGPoint]()
    private var cumulativeDelta = CGVector.zero
    private var cancelPanMomentumCounter = 0
    private var behavior = PinchBehavior.idle
    private var idleSpread: CGFloat!
    private var activeSpread: CGFloat?

    
    // MARK: Init

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers")
        self.fingers = fingers
        super.init()
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {

        positionForTouch[touch] = touch.position

        guard fingers == properties.touchCount else {
            return
        }

        switch state {
        case .momentum:
            // If coming from momentum, we want to keep the first touch that went down still
            let temp = positionForTouch
            reset()
            positionForTouch = temp
            fallthrough
        case .possible:
            momentumTimer?.invalidate()
            cumulativeDelta = .zero
            spreads.add(properties.spread)
            lastPosition = properties.cog
            positionForTouch[touch] = touch.position
            locations.add(properties.cog)
            state = .began
            timeOfLastUpdate = Date()
            gestureUpdated?(self)
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastPositionOfTouch = positionForTouch[touch] else {
            return
        }

        // Tracks all touches in positionsForTouch
        positionForTouch[touch] = touch.position

        guard let lastSpread = spreads.last, let currentLocation = locations.last, properties.touchCount == fingers else {
            cancelPanMomentumCounter += 1
            if cancelPanMomentumCounter >= Constants.cancelPanMomentumCounterThreshold {
                locations.clearSecondLast()
            }
            return
        }

        cancelPanMomentumCounter = 0

        switch state {
        case .began:
            idleSpread = lastSpread
            lastSpreadSinceUpdate = lastSpread
            behavior = behavior(of: properties.spread)
            state = .recognized
            fallthrough
        case .recognized:
            updatePinch(with: properties)
            updatePan(touch, with: currentLocation, lastPositionOfTouch)
            if shouldUpdate(for: timeOfLastUpdate) {
               sendUpdate(with: properties)
            }
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {

        positionForTouch.removeValue(forKey: touch)

        guard properties.touchCount.isZero else {
            return
        }

        let stateBeforeEnded = state
        state = .ended
        gestureUpdated?(self)

        if let velocity = panVelocity, let scale = pinchScale, stateBeforeEnded == .recognized {
            beginMomentum(velocity, scale)
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    func reset() {
        positionForTouch.removeAll()
        state = .possible
        scale = Constants.initialScale
        behavior = .idle
        lastPosition = nil
        spreads.clear()
        delta = .zero
        cancelPanMomentumCounter = 0
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
        return scaleFollowsBehavior(last/secondLast) ? (last / secondLast) : Constants.initialScale
    }
    
    private func beginMomentum(_ velocity: CGVector, _ scale: CGFloat) {
        state = .momentum
        panFrictionFactor = Momentum.panInitialFrictionFactor
        pinchFrictionFactor = Momentum.pinchInitialFrictionFactor
        delta = velocity * CGFloat(fingers)
        self.scale = scale
        gestureUpdated?(self)

        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: Constants.updateTimeInterval, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        updatePinchMomentum()
        updatePanMomentum()

        guard delta != .zero || scale != Constants.initialScale else {
            endMomentum()
            return
        }
        gestureUpdated?(self)
    }

    private func endMomentum() {
        momentumTimer?.invalidate()
        reset()
        gestureUpdated?(self)
    }


    // MARK: Pinch behavior

    /// Returns the behavior of the spread based off the current last spread.
    private func behavior(of spread: CGFloat) -> PinchBehavior {
        guard let lastSpread = spreads.last else {
            idleSpread = spread
            return .idle
        }

        // If it was idle and passes a threshold, set it to a non-idle behavior
        if behavior == .idle && abs(spread - idleSpread) > Constants.fromIdleBehaviorChangeThreshold {
            activeSpread = nil
            return (spread - idleSpread) > 0 ? PinchBehavior.growing : PinchBehavior.shrinking
        }

        if behavior != .idle {
            // If the new behavior is different, save the spread at which this changed, if a threshold is passed then go back to idle
            if ((spread - lastSpread) > 0 ? PinchBehavior.growing : PinchBehavior.shrinking) != behavior {
                if activeSpread == nil {
                    activeSpread = spread
                }

                if abs(activeSpread! - spread) > Constants.toIdleBehaviorChangeThreshold {
                    idleSpread = spread
                    return .idle
                }
            } else {
                updateIfSpreadContinued(with: spread)
            }
        }
        return behavior
    }


    // MARK: Helpers

    private func updatePan(_ touch: Touch, with currentLocation: CGPoint, _ lastPositionOfTouch: CGPoint) {
        let touchVector = (touch.position - lastPositionOfTouch).asVector
        cumulativeDelta += touchVector / 2
        locations.add(currentLocation + touchVector / CGFloat(fingers))
    }

    private func updatePinch(with properties: TouchProperties) {
        // spreads MUST be added after behavior is set
        behavior = behavior(of: properties.spread)

        if behavior != .idle {
            spreads.add(properties.spread)
            lastPosition = properties.cog
        } else {
            lastSpreadSinceUpdate = properties.spread
        }
    }

    private func sendUpdate(with properties: TouchProperties) {
        scale = properties.spread / lastSpreadSinceUpdate

        // Filters out small tremors, if it is in the growing state, it can only grow and vise versa, ignores very small spreads where fingers are close together
        if scaleFollowsBehavior(scale) && properties.spread > 30{
            lastSpreadSinceUpdate = properties.spread
        } else {
            scale = Constants.initialScale
        }
        if cumulativeDelta.magnitude > Constants.minimumDeltaUpdateThreshold {
            delta = cumulativeDelta
            cumulativeDelta = .zero
        }
        timeOfLastUpdate = Date()
        gestureUpdated?(self)
        delta = .zero
        scale = Constants.initialScale
    }

    private func scaleFollowsBehavior(_ scale: CGFloat) -> Bool {
        return (scale > 1 && behavior == .growing) || (scale < 1 && behavior == .shrinking)
    }

    private func updatePinchMomentum() {
        if abs(scale - 1) < Momentum.pinchThresholdMomentumScale {
            scale = Constants.initialScale
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

    /// If the pinch continued in the direction of the gesture, clear the activeSpread
    private func updateIfSpreadContinued(with spread: CGFloat) {
        if let activeSpread = activeSpread {
            if behavior == .growing {
                if spread - activeSpread > 3 {
                    self.activeSpread = nil
                }
            } else {
                if activeSpread - spread > 3 {
                    self.activeSpread = nil
                }
            }
        }
    }

    /// Returns true if the given spread is of the same behavior type, or the current behavior is idle
    private func shouldUpdate(with newSpread: CGFloat) -> Bool {
        return behavior == behavior(of: newSpread) && behavior != .idle
    }

    /// Returns true if enough time has passed to send send the next update
    private func shouldUpdate(for time: Date) -> Bool {
        return abs(time.timeIntervalSinceNow) > Constants.updateTimeInterval
    }
}
