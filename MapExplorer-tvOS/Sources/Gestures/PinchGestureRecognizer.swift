//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class PinchGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let initialScale: CGFloat = 1.0
        static let minimumFingers = 2
        static let minimumSpreadThreshhold: CGFloat = 0.1
        static let thresholdMomentumScale: CGFloat = 0.0001
        static let frictionFactor: CGFloat = 1.01
        static let frictionFactorScale: CGFloat = 0.005
    }

    private var momentumTimer: Timer?
    var state = GestureState.possible
    var lastSpread: CGFloat!
    var lastPosition: CGPoint!
    var scale: CGFloat = Constants.initialScale
    var fingers: Int
    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?
    var delta = CGVector.zero
    var spreads = [CGFloat?]()
    

    init(withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers")
        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        if state == .began {
            state = .failed
        } else if (state == .possible || state == .momentum)  && fingers == properties.touchCount {
            self.momentumTimer?.invalidate()
            state = .began
            spreads.append(properties.spread)
            lastPosition = properties.cog
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let lastSpread = getLastSpreads().last, let lastPosition = lastPosition else {
            return
        }

        switch state {
        case .began where abs(properties.spread / lastSpread - 1.0) > Constants.minimumSpreadThreshhold:
            gestureUpdated?(self)
            state = .recognized
            gestureRecognized?(self)
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
        if !properties.touchCount.isZero {
            state = .failed
        }

        guard let lastSpread = getLastSpreads().last, let secondLastSpread = getLastSpreads().secondLast else {
            state = .possible
            return
        }

        beginMomentum(lastSpread, secondLastSpread, with: properties)
    }

    func reset() {
        if state != .momentum {
            state = .possible
            scale = Constants.initialScale
            delta = .zero
            lastSpread = nil
            lastPosition = nil
        }
    }

    func invalidate() {
        state = .failed
    }

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

        var frictionFactor = Constants.frictionFactor
        var testScale = lastSpread / secondLastSpread - 1

        self.momentumTimer?.invalidate()
        momentumTimer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { _ in
            if abs(1 - self.scale) < Constants.thresholdMomentumScale {
                self.endMomentum()
                return
            }
            self.scale = 1 + testScale
            self.gestureUpdated?(self)
            frictionFactor += Constants.frictionFactorScale
            testScale /= frictionFactor
        }
    }

    private func endMomentum() {
        self.momentumTimer?.invalidate()
        self.state = .possible
        self.reset()
    }
}
