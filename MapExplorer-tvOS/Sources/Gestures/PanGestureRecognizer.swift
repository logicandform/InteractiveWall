//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PanGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let recognizedThreshhold: CGFloat = 100
        static let minimumFingers = 1
        static let thresholdMomentumDelta: Double = 8
        static let frictionFactor = 1.05
        static let frictionFactorScale = 0.001
    }

    private var momentumTimer: Timer?
    var state = GestureState.possible
    var delta = CGVector.zero
    var fingers: [Int]
    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?
    var lastTouchCount: Int?
    var positions = [CGPoint?]()


    init(withFingers fingers: [Int] = [1]) {
        for finger in fingers {
             precondition(finger >= Constants.minimumFingers, "\(finger) is an invalid number of fingers, errors will occur")
        }
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        if state == .began && properties.touchCount == lastTouchCount {
            state = .failed
        } else if (state == .possible || state == .momentum) && fingers.contains(properties.touchCount) {
            self.momentumTimer?.invalidate()
            state = .began
            positions.append(properties.cog)
            lastTouchCount = properties.touchCount
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastPosition = getLastPositions().last else {
            return
        }

        switch state {
        case .began where abs(properties.cog.x - lastPosition.x) + abs(properties.cog.y - lastPosition.y) > Constants.recognizedThreshhold:
            gestureUpdated?(self)
            state = .recognized
            gestureRecognized?(self)
        case .recognized:
            delta = CGVector(dx: properties.cog.x - lastPosition.x, dy: properties.cog.y - lastPosition.y)
            positions.append(properties.cog)
            gestureUpdated?(self)
            lastTouchCount = properties.touchCount
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {

        guard properties.touchCount.isZero else {
            return
        }

        guard let lastPosition = getLastPositions().last, let secondLastPosition = getLastPositions().secondLast else {
            state = .possible
            return
        }

        beginMomentum(lastPosition, secondLastPosition, with: properties)
    }

    func reset() {
        if state != .momentum {
            state = .possible
            positions.removeAll()
            delta = .zero
        }
    }

    func invalidate() {
        state = .failed
    }

    private func getLastPositions() -> (last: CGPoint?, secondLast: CGPoint?) {
        var last: CGPoint?
        var secondLast: CGPoint?

        if !positions.isEmpty {
            last = positions[positions.count - 1]
        }
        if positions.count >= 3 {
            secondLast = positions[positions.count - 3]
        }
        return (last, secondLast)
    }

    private func beginMomentum(_ lastPosition: CGPoint, _ secondLastPosition: CGPoint, with properties: TouchProperties) {
        guard let lastTouchCount = lastTouchCount else {
            return
        }

        state = .momentum
        var frictionFactor = Constants.frictionFactor
        delta = CGVector(dx: lastPosition.x - secondLastPosition.x, dy: lastPosition.y - secondLastPosition.y)
        delta *= Double(lastTouchCount)
        self.momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            if self.delta.magnitude < Constants.thresholdMomentumDelta {
                self.momentumTimer?.invalidate()
                self.state = .possible
                self.reset()
                return
            }
            self.gestureUpdated?(self)
            frictionFactor += Constants.frictionFactorScale
           // self.delta /= frictionFactor
        }
    }
}
