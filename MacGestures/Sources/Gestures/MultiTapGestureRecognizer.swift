//  Copyright © 2018 JABT. All rights reserved.

import Foundation


/// Gesture for registered multiple tap gestures simultaneously. Must use `touchUpdated` block instead of `gestureUpdated`.
public class MultiTapGestureRecognizer: NSObject, GestureRecognizer {

    public var gestureUpdated: ((GestureRecognizer) -> Void)?
    public var touchUpdated: ((Touch, GestureState) -> Void)?
    private(set) public var state = GestureState.possible
    private(set) public var position: CGPoint?
    private var initialPositionForTouch = [Touch: CGPoint]()
    private var stateForTouch = [Touch: GestureState]()
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
        initialPositionForTouch[touch] = touch.position
        stateForTouch[touch] = .began

        if delayTap {
            startDelayedTimer(for: touch)
        } else {
            recognize(touch: touch)
        }
    }

    public func move(_ touch: Touch, with properties: TouchProperties) {
        guard let initialPosition = initialPositionForTouch[touch], let touchState = stateForTouch[touch], touchState != .ended else {
            return
        }

        let delta = CGVector(dx: initialPosition.x - touch.position.x, dy: initialPosition.y - touch.position.y)
        let distance = sqrt(pow(delta.dx, 2) + pow(delta.dy, 2))
        if distance > Constants.maximumDistanceMoved {
            stateForTouch[touch] = .failed
            if cancelOnMove {
                end(touch, with: properties)
            } else {
                touchUpdated?(touch, .failed)
                stateForTouch[touch] = .ended
            }
        }
    }

    public func end(_ touch: Touch, with properties: TouchProperties) {
        guard let touchState = stateForTouch[touch] else {
            return
        }

        switch touchState {
        case .failed:
            touchUpdated?(touch, touchState)
        case .began:
            touchUpdated?(touch, touchState)
            fallthrough
        default:
            stateForTouch[touch] = .ended
            touchUpdated?(touch, .ended)
        }

        initialPositionForTouch.removeValue(forKey: touch)
        stateForTouch.removeValue(forKey: touch)
    }

    public func reset() {
        initialPositionForTouch.removeAll()
        stateForTouch.removeAll()
    }

    public func invalidate() {

    }


    // MARK: Helpers

    private func recognize(touch: Touch) {
        if let touchState = stateForTouch[touch] {
            touchUpdated?(touch, touchState)
            stateForTouch[touch] = .recognized
        }
    }

    private func startDelayedTimer(for touch: Touch) {
        Timer.scheduledTimer(withTimeInterval: Constants.delayedTapDuration, repeats: false) { [weak self] _ in
            self?.delayedTimerFired(for: touch)
        }
    }

    private func delayedTimerFired(for touch: Touch) {
        if let state = stateForTouch[touch], state == .began {
            recognize(touch: touch)
        }
    }
}
