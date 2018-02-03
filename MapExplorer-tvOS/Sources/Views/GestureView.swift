//  Copyright © 2018 slant. All rights reserved.

import UIKit
import C4

class GestureView: UIView {

    private let gestureHandler = GestureHandler()


    // MARK: API

    func add(_ gesture: GestureRecognizer) {
        gestureHandler.add(gesture)
    }

    func handle(_ touch: Touch) {
        gestureHandler.handle(touch)
    }

    func owns(_ touch: Touch) -> Bool {
        return gestureHandler.touches.contains(touch)
    }

    func view(for point: CGPoint) -> GestureView? {
        guard frame.contains(point) else {
            return nil
        }

        let gestureViews = subviews.flatMap { $0 as? GestureView }
        let pointInBounds = transformedFromParent(point)

        for subview in gestureViews.reversed() {
            if let target = subview.view(for: pointInBounds) {
                return target
            }
        }

        return self
    }


    // MARK: Helpers

    private func transformedFromParent(_ point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x - frame.origin.x, y: point.y - frame.origin.y)
    }

}
