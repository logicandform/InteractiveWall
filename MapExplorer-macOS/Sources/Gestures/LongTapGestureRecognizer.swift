//  Copyright © 2017 JABT. All rights reserved.

import Foundation
import AppKit

class LongTapGestureRecognizer: NSObject, GestureRecognizer {

    private struct Constants {
        static let maximumDistanceMoved: CGFloat = 20
        static let minimumFingers = 1
        static let startTapThresholdTime = 0.15
        static let recognizeDoubleTapMaxTime = 0.5
        static let recognizeDoubleTapMaxDistance: CGFloat = 40
    }

    var gestureUpdated: ((GestureRecognizer) -> Void)?
    var longTapUpdate: ((GestureRecognizer, Touch) -> Void)?
    var position: CGPoint?
    private(set) var state = GestureState.possible

    private var positionForTouch = [Touch: CGPoint]()
    private var delayTap: Bool


    // MARK: Init
    init(withDelay: Bool = false) {
        self.delayTap = withDelay
    }


    // MARK: API

    func start(_ touch: Touch, with properties: TouchProperties) {
        positionForTouch[touch] = touch.position
        position = touch.position
        state = .began

        if !delayTap {
            longTapUpdate?(self, touch)
            state = .recognized
            return
        }
    }

    func move(_ touch: Touch, with properties: TouchProperties) {
        return
    }

    func end(_ touch: Touch, with properties: TouchProperties) {
        guard positionForTouch.keys.contains(touch) else {
            return
        }

        position = touch.position
        state = .ended
        longTapUpdate?(self, touch)

        reset()
        positionForTouch.removeValue(forKey: touch)
    }

    func reset() {
        state = .possible
    }
}
