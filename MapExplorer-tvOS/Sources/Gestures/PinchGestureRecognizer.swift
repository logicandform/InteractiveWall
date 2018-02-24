//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit


fileprivate enum PinchBehavior: String {
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
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    
    private(set) var lastPosition: CGPoint!
    private(set) var state = GestureState.possible
    private(set) var scale: CGFloat = Constants.initialScale
    private(set) var delta = CGVector.zero
    private(set) var fingers: Int
    private var spreads = LastThree<CGFloat>()
    private var behavior = PinchBehavior.idle


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
            momentumTimer?.invalidate()
            spreads.add(properties.spread)
            lastPosition = properties.cog
            state = .began
            gestureUpdated?(self)
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastSpread = spreads.last, let currentPosition = lastPosition, properties.touchCount == fingers else {
            return
        }

        switch state {
        case .began where abs(properties.spread / lastSpread - 1.0) > Constants.minimumSpreadThreshold:
            behavior = behavior(of: properties.spread)
            state = .recognized
            fallthrough
        case .recognized:
            if shouldUpdate(with: properties.spread) {
                scale = properties.spread / lastSpread
                delta = CGVector(dx: properties.cog.x - currentPosition.x, dy: properties.cog.y - currentPosition.y)
                spreads.add(properties.spread)
                lastPosition = properties.cog
                gestureUpdated?(self)
            } else if changedBehavior(from: lastSpread, to: properties.spread) {
                scale = Constants.initialScale
                behavior = behavior(of: properties.spread)
                spreads.add(properties.spread)
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

        if let lastSpread = spreads.last, let secondLastSpread = spreads.secondLast {
            beginMomentum(lastSpread, secondLastSpread, with: properties)
        } else {
            reset()
            gestureUpdated?(self)
        }
    }

    func reset() {
        state = .possible
        scale = Constants.initialScale
        delta = .zero
        spreads.clear()
        lastPosition = nil
    }


    // MARK: Momentium

    private var momentumTimer: Timer?
    private var frictionFactor = Momentum.initialFrictionFactor

    private struct Momentum {
        static let thresholdMomentumScale: CGFloat = 0.0001
        static let initialFrictionFactor: CGFloat = 1.01
        static let frictionFactorScale: CGFloat = 0.005
    }

    private func beginMomentum(_ lastSpread: CGFloat, _ secondLastSpread: CGFloat, with properties: TouchProperties) {
        state = .momentum
        frictionFactor = Momentum.initialFrictionFactor
        scale = lastSpread / secondLastSpread
        gestureUpdated?(self)

        self.momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { [weak self] _ in
            self?.updateMomentum()
        }
    }

    private func updateMomentum() {
        guard abs(scale - 1) > Momentum.thresholdMomentumScale else {
            endMomentum()
            return
        }

        scale /= frictionFactor
        frictionFactor += Momentum.frictionFactorScale
        gestureUpdated?(self)
    }

    private func endMomentum() {
        self.momentumTimer?.invalidate()
        self.reset()
        gestureUpdated?(self)
    }


    // MARK: Pinch behavior

    private func behavior(of spread: CGFloat) -> PinchBehavior {
        guard let lastSpread = spreads.last else {
            return .idle
        }

        return (spread - lastSpread > 0) ? .growing : .shrinking
    }

    private func shouldUpdate(with newSpread: CGFloat) -> Bool {
        return behavior == behavior(of: newSpread) || behavior == .idle
    }

    private func changedBehavior(from oldSpread: CGFloat, to newSpread: CGFloat) -> Bool {
        if behavior != behavior(of: newSpread), abs(oldSpread - newSpread) > Constants.minimumBehaviorChangeThreshold {
            return true
        }

        return false
    }
}
