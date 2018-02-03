//  Copyright © 2017 JABT. All rights reserved.

import UIKit
import C4

protocol TouchResponder: class {
    var view: UIView! { get }
    func view(for point: CGPoint) -> GestureView?
}

class TouchHandler {

    private struct Constants {
        static let planarScreenSize = CGSize(width: 4095, height: 4095)
    }

    let responder: TouchResponder

    init(responder: TouchResponder) {
        self.responder = responder
    }


    // MARK: API

    func handle(_ touch: Touch) {
        // Convert to device coordinate system
        convertToScreen(touch)

        // Pass touch to proper gesture view
        switch touch.state {
        case .down:
            handleTouchDown(touch)
        case .up, .moved:
            let gestureViews = responder.view.subviews.flatMap { $0 as? GestureView }
            for view in gestureViews {
                if view.owns(touch) {
                    view.handle(touch)
                }
            }
        }
    }


    // MARK: Helpers

    private func handleTouchDown(_ touch: Touch) {
        guard let receiver = responder.view(for: touch.position) else {
            return
        }

        receiver.handle(touch)
    }

    /// Converts a position received from a planar screen to the coordinate of the current devices bounds.
    private func convertToScreen(_ touch: Touch) {
        let screen = UIScreen.main.bounds
        let xPos = touch.position.x / Constants.planarScreenSize.width * CGFloat(screen.width)
        let yPos = touch.position.y / Constants.planarScreenSize.height * CGFloat(screen.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }
}
