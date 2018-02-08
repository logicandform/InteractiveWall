//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

enum SwipeDirection {
    case up
    case down
    case left
    case right
}

class SwipeGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let rotationThresh: CGFloat = .pi / 8
        static let deltaThresh: CGFloat = 50
        static let timerInterval = 0.08
        static let minimumFingers = 1
    }

    var state = NSGestureRecognizer.State.possible
    var delta = CGVector.zero
    var startPosition: CGPoint?
    var angle: CGFloat
    var fingers: Int

    var timer = Timer()

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var gestureRecognized: ((GestureRecognizer) -> Void)?

    init(direction: SwipeDirection, withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")
        self.angle = SwipeGestureRecognizer.angle(for: direction)
        self.fingers = fingers
        super.init()
    }

    init(angle: CGFloat, withFingers fingers: Int = Constants.minimumFingers) {
        precondition(fingers >= Constants.minimumFingers, "\(fingers) is an invalid number of fingers, errors will occur")

        self.angle = angle.remainder(dividingBy: .pi * 2)
        if self.angle > .pi {
            self.angle -= .pi*2
        }

        self.fingers = fingers
        super.init()
    }

    func start(_ touch: Touch, with properties: TouchProperties) {
        switch state {
        case .began:
            state = .failed
        case .possible where properties.touchCount == fingers:
            state = .began
            startPosition = properties.cog
            timer.invalidate()
            timer = Timer.scheduledTimer(timeInterval: Constants.timerInterval, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        default:
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        guard let startPosition = startPosition else {
            return
        }

        switch state {
        case .recognized, .began:
            delta = CGVector(dx: properties.cog.x - startPosition.x, dy: properties.cog.y - startPosition.y)
            fallthrough
        case .began where abs(delta.dx) + abs(delta.dy) > Constants.deltaThresh:
            if abs(atan2(delta.dy, delta.dx) - angle) < Constants.rotationThresh {
                state = .recognized
                gestureRecognized?(self)
                timer.invalidate()
                timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
            } else {
                state = .failed
            }
        default:
            return
        }
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        if state == .recognized && abs(atan2(delta.dy, delta.dx) - angle) < Constants.rotationThresh && sqrt(delta.dx*delta.dx + delta.dy*delta.dy) > 400.0 {
            gestureUpdated?(self)
        }
        state = .possible
    }

    func reset() {
        timer.invalidate()
        state = .possible
        delta = .zero
    }

    func invalidate() {
        timer.invalidate()
        state = .failed
    }

    @objc
    func timeout() {
        timer.invalidate()
        state = .possible
    }


    // MARK: Helpers

    static private func angle(for direction: SwipeDirection) -> CGFloat {
        switch direction {
        case .down:
            return .pi / 2.0
        case .up:
            return -.pi / 2
        case .left:
            return .pi
        case .right:
            return 0
        }
    }
}
