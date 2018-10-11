//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit


public class TapGestureRecognizer: NSObject, GestureRecognizer {

    public var gestureUpdated: ((GestureRecognizer) -> Void)?
    private(set) public var state = GestureState.possible
    private(set) public var position: CGPoint?

    private var positionForTouch = [Touch: CGPoint]()
    private let delayTap: Bool
    private let cancelOnMove: Bool

    private struct Constants {
        static let maximumDistanceMoved: CGFloat = 20
        static let delayedTapDuration = 0.15
    }


    // MARK: Init
    
    public init(withDelay: Bool = false, cancelsOnMove: Bool = true) {
        self.delayTap = withDelay
        self.cancelOnMove = cancelsOnMove
    }


    // MARK: API

    public func start(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch[touch] = touch.position
        position = touch.position
        state = .began

        if delayTap {
            startDelayedTimer(for: touch)
        } else {
            recognize(touch: touch)
        }
    }

    public func move(_ touch: Touch, with properties: TouchProperties) {
        guard let initialPosition = positionForTouch[touch], state != .ended else {
            return
        }

        let delta = CGVector(dx: initialPosition.x - touch.position.x, dy: initialPosition.y - touch.position.y)
        let distance = sqrt(pow(delta.dx, 2) + pow(delta.dy, 2))
        if distance > Constants.maximumDistanceMoved {
            state = .failed
            if cancelOnMove {
                end(touch, with: properties)
            } else {
                state = .ended
            }
        }
    }

    public func end(_ touch: Touch, with properties: TouchProperties) {
        guard positionForTouch.keys.contains(touch) else {
            return
        }

        position = touch.position

        switch state {
        case .failed:
            gestureUpdated?(self)
        case .began:
            gestureUpdated?(self)
            fallthrough
        default:
            state = .ended
            gestureUpdated?(self)
        }

        reset()
        positionForTouch.removeValue(forKey: touch)
    }

    public func reset() {
        state = .possible
    }

    public func invalidate() {
        
    }


    // MARK: Helpers

    private func recognize(touch: Touch) {
        gestureUpdated?(self)
        state = .recognized
    }

    private func startDelayedTimer(for touch: Touch) {
        Timer.scheduledTimer(withTimeInterval: Constants.delayedTapDuration, repeats: false) { [weak self] _ in
            self?.delayedTimerFired(for: touch)
        }
    }

    private func delayedTimerFired(for touch: Touch) {
        if state == .began {
            recognize(touch: touch)
        }
    }
}
