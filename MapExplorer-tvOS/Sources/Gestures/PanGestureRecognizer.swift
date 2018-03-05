//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 20
        static let minimumFingers = 1
        static let minimumDeltaUpdateThreshold: Double = 4
        static let updateTimeInterval: TimeInterval = 1 / 60
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) var state = GestureState.possible
    private(set) var delta = CGVector.zero
    private(set) var fingers: [Int]
    private(set) var locations = LastThree<CGPoint>()
    private var positionForTouch = [Touch: CGPoint]()
    private var lastTouchCount: Int!
    private var cumulativeDelta = CGVector.zero
    private var timeOfLastUpdate = Date()


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

        switch state {
        case .possible, .momentum:
            cumulativeDelta = .zero
            state = .began
            locations.add(properties.cog)
            fallthrough
        case .recognized:
            positionForTouch[touch] = touch.position
            momentumTimer?.invalidate()
            lastTouchCount = positionForTouch.keys.count
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let currentLocation = locations.last, let lastPositionOfTouch = positionForTouch[touch], positionForTouch.keys.contains(touch) else {
            return
        }

        switch state {
        case .began where shouldRecognize(properties: properties, for: currentLocation):
            state = .recognized
            fallthrough
        case .recognized:
            lastTouchCount = positionForTouch.keys.count
            positionForTouch[touch] = touch.position
            let offset = touch.position - lastPositionOfTouch
            update(location: currentLocation, with: offset.asVector)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch.removeValue(forKey: touch)

        guard properties.touchCount.isZero && state == .recognized else {
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

        if cumulativeDelta.magnitude > Constants.minimumDeltaUpdateThreshold && abs(timeOfLastUpdate.timeIntervalSinceNow) > Constants.updateTimeInterval {
            delta = cumulativeDelta
            cumulativeDelta = .zero
            timeOfLastUpdate = Date()
            gestureUpdated?(self)
        }
    }


    // MARK: Momentum

    private struct Momentum {
        static let initialFrictionFactor = 1.05
        static let frictionFactorScale = 0.001
        static let minimumDeltaThreshold: Double = 0.8
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
        momentumTimer = Timer.scheduledTimer(withTimeInterval: Constants.updateTimeInterval, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        guard delta.magnitude > Momentum.minimumDeltaThreshold else {
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
