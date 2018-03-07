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
        static let minimumSpreadThreshold: CGFloat = 0.1
        static let minimumBehaviorChangeThreshold: CGFloat = 15
        static let updateTimeInterval: Double = 1 / 380
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) var lastPosition: CGPoint!
    private(set) var state = GestureState.possible
    private(set) var scale: CGFloat = Constants.initialScale
    private var spreads = LastThree<CGFloat>()
    private var behavior = PinchBehavior.idle
    private var timeOfLastUpdate: Date!
    private var lastSpreadSinceUpdate: CGFloat!
    private let fingers: Int
    private var touches = Set<Touch>()


    // MARK: Init

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers")
        self.fingers = fingers
        super.init()
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        guard fingers == properties.touchCount else {
            return
        }

        switch state {
        case .possible, .momentum:
            touches.insert(touch)
            momentumTimer?.invalidate()
            spreads.add(properties.spread)
            lastPosition = properties.cog
            state = .began
            timeOfLastUpdate = Date()
            gestureUpdated?(self)
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastSpread = spreads.last, properties.touchCount == fingers else {
            return
        }

        switch state {
        case .began where abs(properties.spread / lastSpread - 1.0) > Constants.minimumSpreadThreshold:
            behavior = behavior(of: properties.spread)
            state = .recognized
            lastSpreadSinceUpdate = lastSpread
            fallthrough
        case .recognized:
            if shouldUpdate(with: properties.spread) {
                scale = properties.spread / lastSpreadSinceUpdate
                spreads.add(properties.spread)
                lastPosition = properties.cog
                if shouldUpdate(for: timeOfLastUpdate) {
                    lastSpreadSinceUpdate = properties.spread
                    timeOfLastUpdate = Date()
                    gestureUpdated?(self)
                }
            } else if changedBehavior(from: lastSpread, to: properties.spread) {
                scale = Constants.initialScale
                behavior = behavior(of: properties.spread)
                spreads.add(properties.spread)
                lastSpreadSinceUpdate = properties.spread
                timeOfLastUpdate = Date()
                gestureUpdated?(self)
            }
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {

        guard properties.touchCount.isZero else {
            return
        }

        if let lastSpread = spreads.last, let secondLastSpread = spreads.secondLast, state == .recognized {
            beginMomentum(lastSpread, secondLastSpread, with: properties)
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    func reset() {
        state = .possible
        scale = Constants.initialScale
        behavior = .idle
        lastPosition = nil
        spreads.clear()
        touches.removeAll()
    }


    // MARK: Momentium

    private var momentumTimer: Timer?
    private var frictionFactor = Momentum.initialFrictionFactor

    private struct Momentum {
        static let thresholdMomentumScale: CGFloat = 0.0001
        static let initialFrictionFactor: CGFloat = 1.06
        static let frictionFactorScale: CGFloat = 0.004
        static let updateTimeInterval: TimeInterval = 1 / 60
    }

    private func beginMomentum(_ lastSpread: CGFloat, _ secondLastSpread: CGFloat, with properties: TouchProperties) {
        state = .momentum
        frictionFactor = Momentum.initialFrictionFactor
        scale = lastSpread / secondLastSpread
        gestureUpdated?(self)

        momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: Momentum.updateTimeInterval, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        guard abs(scale - 1) > Momentum.thresholdMomentumScale else {
            endMomentum()
            return
        }

        scale -= 1
        scale /= frictionFactor
        scale += 1
        frictionFactor += Momentum.frictionFactorScale
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
            return .idle
        }

        return (spread - lastSpread > 0) ? .growing : .shrinking
    }

    /// Returns true if the given spread is of the same behavior type, or the current behavior is idle
    private func shouldUpdate(with newSpread: CGFloat) -> Bool {
        return behavior == behavior(of: newSpread) || behavior == .idle
    }

    /// Returns true if enough time has passed to send send the next update
    private func shouldUpdate(for time: Date) -> Bool {
        return abs(time.timeIntervalSinceNow) > Constants.updateTimeInterval
    }

    /// If the newSpread has a different behavior and surpasses the minimum threshold, returns true
    private func changedBehavior(from oldSpread: CGFloat, to newSpread: CGFloat) -> Bool {
        if behavior != behavior(of: newSpread), abs(oldSpread - newSpread) > Constants.minimumBehaviorChangeThreshold {
            return true
        }

        return false
    }
}
