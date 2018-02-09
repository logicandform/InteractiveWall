//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit

protocol TouchResponder: class {
    var view: NSView { get }
    func view(for point: CGPoint) -> GestureView?
}

class TouchHandler {

    private struct Constants {
        static let planarScreenSize = CGSize(width: 4095, height: 2242.5)
        static let circleRadius: CGFloat = 20
    }

    let responder: TouchResponder

    init(responder: TouchResponder) {
        self.responder = responder
    }


    // MARK: API

    func handle(_ touch: Touch) {
        convertToResponder(touch)
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
        displayTouchIndicator(at: touch.position)

        if let receiver = responder.view(for: touch.position) {
            receiver.handle(touch)
        }
    }

    /// Converts a position received from a planar screen to the coordinate of the current devices bounds.
    private func convertToResponder(_ touch: Touch) {
        let screen = responder.view.bounds
        let xPos = touch.position.x / Constants.planarScreenSize.width * CGFloat(screen.width)
        let yPos = (1 - touch.position.y / Constants.planarScreenSize.height) * CGFloat(screen.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }

    /// Displays a touch indicator on the screen for testing
    private func displayTouchIndicator(at position: CGPoint) {
        let radius = Constants.circleRadius
        let frame = CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: 2*radius, height: 2*radius))
        let touchIndicator = NSView(frame: frame)
        touchIndicator.wantsLayer = true
        touchIndicator.layer?.cornerRadius = Constants.circleRadius
        touchIndicator.layer?.masksToBounds = true
        touchIndicator.layer?.borderWidth = Constants.circleRadius / 4
        touchIndicator.layer?.borderColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 0.802921661)
        responder.view.addSubview(touchIndicator)
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            touchIndicator.animator().alphaValue = 0.0
        })
    }
}
