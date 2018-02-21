//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 20
        static let minimumFingers = 1
        static let minimumDeltaThreshold: Double = 8
        static let initialFrictionFactor = 1.05
        static let frictionFactorScale = 0.001
        static let momentiumTimeInterval: TimeInterval = 1 / 60
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?
    private(set) var state = GestureState.possible
    private(set) var delta = CGVector.zero
    private(set) var fingers: [Int]

    private var locations = LastThreeStructure<CGPoint>()
    private var positionForTouch = [Touch: CGPoint]()
    private var momentumTimer: Timer?
    private var frictionFactor = Constants.initialFrictionFactor
    private var lastTouchCount: Int?

    private var currentVelocity: CGVector? {
        if let last = locations.last, let secondLast = locations.secondLast {
            return CGVector(dx: last.x - secondLast.x, dy: last.y - secondLast.y)
        }

        return nil
    }


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
        guard var currentLocation = locations.last, let lastPositionOfTouch = positionForTouch[touch] else {
            return
        }

        positionForTouch[touch] = touch.position
        lastTouchCount = properties.touchCount

        switch state {
        case .began where sqrt(pow(properties.cog.x - currentLocation.x, 2) + pow(properties.cog.y - currentLocation.y, 2)) > Constants.recognizedThreshhold:
            state = .recognized
            fallthrough
        case .recognized:
            var touchVector = touch.position - lastPositionOfTouch
            touchVector /= Double(properties.touchCount)
            delta = touchVector
            currentLocation += delta
            locations.add(currentLocation)
            gestureUpdated?(self)
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

    private func beginMomentum(with velocity: CGVector, for touchCount: Int) {
        state = .momentum
        frictionFactor = Constants.initialFrictionFactor
        delta = velocity * CGFloat(touchCount)
        gestureUpdated?(self)

        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: Constants.momentiumTimeInterval, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        guard delta.magnitude > Constants.minimumDeltaThreshold else {
            endMomentum()
            return
        }

        frictionFactor += Constants.frictionFactorScale
        delta /= frictionFactor
        gestureUpdated?(self)
    }

    private func endMomentum() {
        momentumTimer?.invalidate()
        reset()
        gestureUpdated?(self)
    }
}
