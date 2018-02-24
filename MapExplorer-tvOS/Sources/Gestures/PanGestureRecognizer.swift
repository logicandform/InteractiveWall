//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 20
        static let minimumFingers = 1
        static let minimumDeltaThreshold: Double = 8
        static let minimumDeltaUpdateThreshold: Double = 4
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) var state = GestureState.possible
    private(set) var delta = CGVector.zero
    private(set) var fingers: [Int]
    private var locations = LastThree<CGPoint>()
    private var positionForTouch = [Touch: CGPoint]()
    private var lastTouchCount: Int?
    private var cumulativeDelta = CGVector.zero


    // MARK: Init

    init(withFingers fingers: [Int] = [Constants.minimumFingers]) {
        for finger in fingers {
            precondition(finger >= Constants.minimumFingers, "\(finger) is an invalid number of fingers, errors will occur")
        }
        self.fingers = fingers
        super.init()
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        guard fingers.contains(properties.touchCount) else {
            return
        }

        positionForTouch[touch] = touch.position

        switch state {
        case .possible, .momentum:
            state = .began
            locations.add(properties.cog)
            fallthrough
        case .recognized:
            momentumTimer?.invalidate()
            lastTouchCount = properties.touchCount
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let currentLocation = locations.last, let lastPositionOfTouch = positionForTouch[touch] else {
            return
        }

        positionForTouch[touch] = touch.position
        lastTouchCount = properties.touchCount

        switch state {
        case .began where shouldStart(for: currentLocation, with: properties):
            state = .recognized
            fallthrough
        case .recognized:
            updatePosition(for: touch, with: properties, location: currentLocation, lastPosition: lastPositionOfTouch)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch.removeValue(forKey: touch)

        guard properties.touchCount.isZero else {
            return
        }

        if let velocity = currentVelocity, let touchCount = lastTouchCount {
            beginMomentum(with: velocity, for: touchCount)
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    func reset() {
        state = .possible
        locations.clear()
        positionForTouch.removeAll()
        delta = .zero
    }


    // MARK: Helpers

    func shouldStart(for currentLocation: CGPoint, with properties: TouchProperties) -> Bool {
        return sqrt(pow(properties.cog.x - currentLocation.x, 2) + pow(properties.cog.y - currentLocation.y, 2)) > Constants.recognizedThreshhold
    }

    func shouldUpdate() -> Bool {
        return (delta + cumulativeDelta).magnitude > Constants.minimumDeltaUpdateThreshold
    }

    func updatePosition(for touch: Touch, with properties: TouchProperties, location: CGPoint, lastPosition: CGPoint) {
        var touchVector = touch.position - lastPosition
        var currentLocation = location
        touchVector /= Double(properties.touchCount)
        delta = touchVector
        currentLocation += delta
        locations.add(currentLocation)
        if shouldUpdate() {
            delta += cumulativeDelta
            cumulativeDelta = CGVector.zero
            gestureUpdated?(self)
            return
        }
        cumulativeDelta += delta
    }
    

    // MARK: Momentum

    private struct Momentum {
        static let initialFrictionFactor = 1.05
        static let frictionFactorScale = 0.001
        static let momentiumTimeInterval: TimeInterval = 1 / 60
    }

    private var momentumTimer: Timer?
    private var frictionFactor = Momentum.initialFrictionFactor
    private var currentVelocity: CGVector? {
        guard let last = locations.last, let secondLast = locations.secondLast else { return nil }
        return CGVector(dx: last.x - secondLast.x, dy: last.y - secondLast.y)
    }

    private func beginMomentum(with velocity: CGVector, for touchCount: Int) {
        state = .momentum
        frictionFactor = Momentum.initialFrictionFactor
        delta = velocity * CGFloat(touchCount)
        gestureUpdated?(self)

        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: Momentum.momentiumTimeInterval, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        guard delta.magnitude > Constants.minimumDeltaThreshold else {
            endMomentum()
            return
        }

        frictionFactor += Momentum.frictionFactorScale
        delta /= frictionFactor
        gestureUpdated?(self)
    }

    private func endMomentum() {
        momentumTimer?.invalidate()
        reset()
        gestureUpdated?(self)
    }
}
