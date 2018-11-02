//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit


public class PanGestureRecognizer: NSObject, GestureRecognizer {

    public var gestureUpdated: ((GestureRecognizer) -> Void)?

    private(set) public var state = GestureState.possible
    private(set) public var lastLocation: CGPoint?
    private(set) public var delta = CGVector.zero
    private var timeOfLastUpdate = Date()
    private var positionForTouch = [Touch: CGPoint]()
    private var cumulativeDelta = CGVector.zero
    private var recognizedThreshold = Constants.defaultRecognizedThreshold

    private struct Constants {
        static let defaultRecognizedThreshold: CGFloat = 20
        static let minimumDeltaUpdateThreshold = 4.0
        static let gestureDelay = 0.1
    }
    

    // MARK: Init

    public override init() {
        super.init()
        let miliseconds = Int(round(GestureManager.refreshRate * 1000))
        self.momentumTimer = DispatchTimer(interval: .milliseconds(miliseconds), handler: { [weak self] in
            self?.updateMomentum()
        })
    }

    public convenience init(recognizedThreshold: CGFloat = 20, friction: FrictionLevel = .medium) {
        self.init()
        self.recognizedThreshold = recognizedThreshold
        self.panFrictionLevel = friction
    }


    // MARK: API

    public func start(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .momentum, .failed:
            reset()
            fallthrough
        case .possible:
            momentumTimer.suspend()
            cumulativeDelta = .zero
            lastLocation = properties.cog
            state = .began
            gestureUpdated?(self)
            timeOfLastUpdate = Date()
            fallthrough
        case .recognized, .began:
            momentumTimer.suspend()
            positionForTouch[touch] = touch.position
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
            state = .recognized
            positionForTouch[touch] = touch.position
        case .recognized:
            positionForTouch[touch] = touch.position
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
        return CGFloat(hypotf(dx, dy).magnitude) > recognizedThreshold
    }

    public func end(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch.removeValue(forKey: touch)

        guard state != .failed, properties.touchCount.isZero else {
            return
        }

        let shouldStartMomentum = state == .recognized
        state = .ended
        gestureUpdated?(self)

        if shouldStartMomentum, abs(timeOfLastUpdate.timeIntervalSinceNow) < Constants.gestureDelay {
            beginMomentum()
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    public func reset() {
        state = .possible
        positionForTouch.removeAll()
        lastLocation = nil
        delta = .zero
    }

    public func invalidate() {
        momentumTimer.suspend()
        state = .failed
        gestureUpdated?(self)
    }


    // MARK: Helpers

    /// Sets gesture properties during a move event and calls `gestureUpdated` callback
    private func updateForMove(with properties: TouchProperties) {
        delta = cumulativeDelta
        panMomentumDelta = delta
        cumulativeDelta = .zero

        gestureUpdated?(self)
        timeOfLastUpdate = Date()
    }

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
        return abs(time.timeIntervalSinceNow) > GestureManager.refreshRate
    }


    // MARK: Momentum

    private var momentumTimer: DispatchTimer!
    private var panFrictionFactor = Momentum.panInitialFrictionFactor
    private var panFrictionLevel = FrictionLevel.medium
    private var panMomentumDelta = CGVector.zero

    private struct Momentum {
        static let panInitialFrictionFactor = 1.04
        static let panThresholdMomentumDelta = 2.0
    }

    private func beginMomentum() {
        panFrictionFactor = Momentum.panInitialFrictionFactor
        delta = panMomentumDelta
        state = .momentum
        gestureUpdated?(self)
        momentumTimer.resume()
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
            panFrictionFactor += panFrictionLevel.scale
            delta /= panFrictionFactor
        }
    }

    private func endMomentum() {
        momentumTimer.suspend()
        reset()
        gestureUpdated?(self)
    }
}
