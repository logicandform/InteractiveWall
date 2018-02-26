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
    private var lastTouchCount: Int!
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
        case .began where shouldRecognize(properties: properties, for: currentLocation):
            state = .recognized
            fallthrough
        case .recognized:
            let touchVector = touch.position - lastPositionOfTouch
            update(location: currentLocation, with: touchVector)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch.removeValue(forKey: touch)

        guard properties.touchCount.isZero else {
            return
        }

        if let velocity = currentVelocity {
            beginMomentum(with: velocity)
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

    private func shouldRecognize(properties: TouchProperties, for currentLocation: CGPoint) -> Bool {
        return sqrt(pow(properties.cog.x - currentLocation.x, 2) + pow(properties.cog.y - currentLocation.y, 2)) > Constants.recognizedThreshhold
    }

    private func update(location: CGPoint, with touchVector: CGVector) {
        delta = touchVector / CGFloat(lastTouchCount)
        cumulativeDelta += delta
        locations.add(location + delta)

        if cumulativeDelta.magnitude > Constants.minimumDeltaUpdateThreshold {
            delta = cumulativeDelta
            cumulativeDelta = .zero
            gestureUpdated?(self)
        }
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

    private func beginMomentum(with velocity: CGVector) {
        state = .momentum
        frictionFactor = Momentum.initialFrictionFactor
        delta = velocity * CGFloat(lastTouchCount)
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
