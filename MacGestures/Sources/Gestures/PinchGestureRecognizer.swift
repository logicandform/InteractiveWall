//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit


/// Used to define the behavior of a PinchGestureRecognizer as its receiving move updates.
fileprivate enum PinchBehavior: String {
    case growing
    case shrinking
    case idle
}


public class PinchGestureRecognizer: NSObject, GestureRecognizer {

    private struct Pinch {
        static let initialScale: CGFloat = 1
        static let numberOfFingers = 2
        static let minimumSpreadDistance: CGFloat = 60
        static let minimumShrinkScale: CGFloat = 0.4
        static let maximumZoomScale: CGFloat = 2
    }

    private struct Pan {
        static let recognizedThreshold: CGFloat = 20
        static let minimumDeltaUpdateThreshold: Double = 4
        static let gesturePausedTime = 0.1
    }

    public var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) public var state = GestureState.possible
    private(set) public var scale = Pinch.initialScale
    private(set) public var delta = CGVector.zero
    private(set) public var center: CGPoint!
    private var timeOfLastUpdate: Date!
    private var recognizedThreshold: CGFloat = Pan.recognizedThreshold

    // Pinch
    private(set) var lastSpread: CGFloat?
    private var lastSpreadSinceUpdate: CGFloat!
    private var behavior = PinchBehavior.idle
    private var touchesForSpread: (Touch, Touch)?
    private var pinchStartTime: Date?

    // Pan
    private var positionForTouch = [Touch: CGPoint]()
    private var lastLocation: CGPoint?
    private var cumulativeDelta = CGVector.zero


    // MARK: Init

    public convenience init(recognizedThreshold: CGFloat = 20, friction: FrictionLevel = .medium) {
        self.init()
        self.recognizedThreshold = recognizedThreshold
        self.frictionLevel = friction
    }


    // MARK: API

    public func start(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .momentum, .failed:
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
            positionForTouch[touch] = touch.position

            // Pinch
            center = properties.cog

            // Pan
            setTouchesForPinch()
        default:
            return
        }
    }

    public func move(_ touch: Touch, with properties: TouchProperties) {
        guard state != .failed, let lastPositionOfTouch = positionForTouch[touch] else {
            return
        }

        switch state {
        case .began where shouldStart(with: touch, from: lastPositionOfTouch):
            setTouchesForPinch()
            beganPinchMove()
            state = .recognized
            positionForTouch[touch] = touch.position
            updateTouchesForSpread(with: touch)
        case .recognized:
            positionForTouch[touch] = touch.position
            updateTouchesForSpread(with: touch)
            recognizePinchMove()
            recognizePanMove(with: touch, lastPosition: lastPositionOfTouch)

            if shouldUpdate(for: timeOfLastUpdate) {
                updateForMove(with: properties)
            }
        default:
            return
        }
    }

    /// Determines if the pan gesture should become recognized
    public func shouldStart(with touch: Touch, from startPosition: CGPoint) -> Bool {
        let dx = Float(touch.position.x - startPosition.x)
        let dy = Float(touch.position.y - startPosition.y)
        return CGFloat(hypotf(dx, dy).magnitude) > Pan.recognizedThreshold
    }

    /// Sets gesture properties during a move event and calls `gestureUpdated` callback
    private func updateForMove(with properties: TouchProperties) {
        // Pinch
        center = properties.cog
        pinchMomentumScale = scale

        // Pan
        delta = cumulativeDelta
        panMomentumDelta = delta
        cumulativeDelta = .zero

        gestureUpdated?(self)
        timeOfLastUpdate = Date()
        if let touches = touchesForSpread {
            let touchSpread = spread(for: touches)
            lastSpreadSinceUpdate = touchSpread
        }
    }

    public func end(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch.removeValue(forKey: touch)

        let tempPinchStartTime = pinchStartTime
        setTouchesForPinch()
        pinchStartTime = pinchStartTime != nil ? pinchStartTime : tempPinchStartTime

        guard state != .failed, properties.touchCount.isZero else {
            return
        }

        let shouldStartMomentum = state == .recognized
        state = .ended
        gestureUpdated?(self)

        if shouldStartMomentum, abs(timeOfLastUpdate.timeIntervalSinceNow) < Pan.gesturePausedTime {
            beginMomentum()
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    public func reset() {
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

    public func invalidate() {
        momentumTimer?.invalidate()
        state = .failed
        gestureUpdated?(self)
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
            let newScale = touchSpread / lastSpreadSinceUpdate
            if newScale < Pinch.minimumShrinkScale || newScale > Pinch.maximumZoomScale {
                return
            }
            scale = newScale
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
        guard positionForTouch.keys.count == Pinch.numberOfFingers else {
            touchesForSpread = nil
            scale = Pinch.initialScale
            pinchStartTime = nil
            return
        }

        pinchStartTime = Date()
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

    /// If the newSpread has a different behavior and surpasses the minimum threshold, returns true
    private func changedBehavior(from oldSpread: CGFloat, to newSpread: CGFloat) -> Bool {
        if behavior != behavior(of: newSpread), abs(oldSpread - newSpread) > recognizedThreshold {
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
        delta = offset.asVector / CGFloat(positionForTouch.keys.count)
        cumulativeDelta += delta
        lastLocation = currentLocation + delta
    }

    private func shouldUpdateForPan() -> Bool {
        return cumulativeDelta.magnitude > Pan.minimumDeltaUpdateThreshold
    }

    /// Returns true if enough time has passed to send send the next update
    private func shouldUpdate(for time: Date) -> Bool {
        return abs(time.timeIntervalSinceNow) > GestureManager.refreshRate
    }


    // MARK: Momentum

    private var momentumTimer: Timer?
    private var panFrictionFactor = Momentum.panInitialFrictionFactor
    private var panMomentumDelta = CGVector.zero
    private var pinchFrictionFactor = Momentum.pinchInitialFrictionFactor
    private var pinchMomentumScale = Pinch.initialScale
    private var frictionLevel = FrictionLevel.medium

    private struct Momentum {
        static let pinchThresholdMomentumScale: CGFloat = 0.0001
        static let pinchInitialFrictionFactor: CGFloat = 1.15
        static let minimumPinchTimeToStart = 0.1
        static let maximumPinchScaleAboutZero: CGFloat = 0.2
        static let panInitialFrictionFactor = 1.04
        static let panThresholdMomentumDelta: Double = 2
        static let panStartMinimumMomentumDelta: Double = 5
    }

    private func beginMomentum() {
        // Pinch
        pinchFrictionFactor = Momentum.pinchInitialFrictionFactor
        setMomentumScale()

        // Pan
        panFrictionFactor = Momentum.panInitialFrictionFactor
        delta = panMomentumDelta.magnitude > Momentum.panStartMinimumMomentumDelta ? panMomentumDelta : .zero

        state = .momentum
        gestureUpdated?(self)
        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: GestureManager.refreshRate, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    /// Gets the momentum scale, filtering out pinches that are too short in time, and clamping it
    private func setMomentumScale() {
        if let startTime = pinchStartTime, abs(startTime.timeIntervalSinceNow) > Momentum.minimumPinchTimeToStart {
            scale = clamp(pinchMomentumScale, min: Pinch.initialScale - Momentum.maximumPinchScaleAboutZero, max: Pinch.initialScale + Momentum.maximumPinchScaleAboutZero)
        } else {
            scale = Pinch.initialScale
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
            pinchFrictionFactor += CGFloat(frictionLevel.scale)
        }
    }

    private func updatePanMomentum() {
        if delta.magnitude < Momentum.panThresholdMomentumDelta {
            delta = .zero
        } else {
            panFrictionFactor += frictionLevel.scale
            delta /= panFrictionFactor
        }
    }

    private func endMomentum() {
        momentumTimer?.invalidate()
        reset()
        gestureUpdated?(self)
    }
}
