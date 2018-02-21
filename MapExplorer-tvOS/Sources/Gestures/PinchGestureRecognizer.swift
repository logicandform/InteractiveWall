//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PinchGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let initialScale: CGFloat = 1.0
        static let minimumFingers = 2
        static let minimumSpreadThreshhold: CGFloat = 0.1
        static let thresholdMomentumScale: CGFloat = 0.0001
        static let initialFrictionFactor: CGFloat = 1.01
        static let frictionFactorScale: CGFloat = 0.005
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var lastPosition: CGPoint!
    private(set) var state = GestureState.possible
    private(set) var scale: CGFloat = Constants.initialScale
    private(set) var delta = CGVector.zero
    private(set) var fingers: Int

    private var momentumTimer: Timer?
    private var spreads = [CGFloat?]() 
    private var frictionFactor = Constants.initialFrictionFactor
    private var scaleDifference: CGFloat = 0


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
            self.momentumTimer?.invalidate()
            state = .began
            spreads.append(properties.spread)
            lastPosition = properties.cog
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastSpread = getLastSpreads().last, let lastPosition = lastPosition, properties.touchCount == fingers else {
            return
        }

        switch state {
        case .began where abs(properties.spread / lastSpread - 1.0) > Constants.minimumSpreadThreshhold:
            state = .recognized
            fallthrough
        case .recognized:
            scale = properties.spread / lastSpread
            delta = CGVector(dx: properties.cog.x - lastPosition.x, dy: properties.cog.y - lastPosition.y)
            spreads.append(properties.spread)
            self.lastPosition = properties.cog
            gestureUpdated?(self)
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        guard properties.touchCount.isZero else {
            return
        }

        if let lastSpread = getLastSpreads().last, let secondLastSpread = getLastSpreads().secondLast {
            beginMomentum(lastSpread, secondLastSpread, with: properties)
        } else {
            reset()
        }
    }

    func reset() {
        state = .possible
        scale = Constants.initialScale
        delta = .zero
        spreads.removeAll()
        lastPosition = nil
    }


    // MARK: Helpers

    private func getLastSpreads() -> (last: CGFloat?, secondLast: CGFloat?) {
        var last: CGFloat?
        var secondLast: CGFloat?

        if !spreads.isEmpty {
            last = spreads[spreads.count - 1]
        }
        if spreads.count >= 2 {
            secondLast = spreads[spreads.count - 2]
        }
        return (last, secondLast)
    }

    private func beginMomentum(_ lastSpread: CGFloat, _ secondLastSpread: CGFloat, with properties: TouchProperties) {
        state = .momentum
        frictionFactor = Constants.initialFrictionFactor
        scaleDifference = lastSpread / secondLastSpread - 1

        self.momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            self.updateMomentum()
        }
    }

    private func updateMomentum() {
        guard abs(scaleDifference) > Constants.thresholdMomentumScale else {
            endMomentum()
            return
        }

        scale = 1 + scaleDifference
        frictionFactor += Constants.frictionFactorScale
        scaleDifference /= frictionFactor
        gestureUpdated?(self)
    }

    private func endMomentum() {
        self.momentumTimer?.invalidate()
        self.reset()
    }
}
