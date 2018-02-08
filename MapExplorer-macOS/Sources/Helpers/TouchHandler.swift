//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

protocol TouchResponder: class {
    var view: NSView { get }
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
}
