//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


protocol GestureResponder: class {
    var view: NSView { get }
}


final class GestureManager {

    private struct Constants {
        static let planarScreenSize = CGSize(width: 4095, height: 2242.5)
        static let indicatorRadius: CGFloat = 20
    }

    private weak var responder: GestureResponder!
    private var gestureHandlers = [NSView: GestureHandler]()

    init(responder: GestureResponder) {
        self.responder = responder
    }


    // MARK: API

    func add(_ gesture: GestureRecognizer, to view: NSView) {
        guard let handler = gestureHandlers[view] else {
            gestureHandlers[view] = GestureHandler(gestures: [gesture])
            return
        }

        handler.add(gesture)
    }

    func remove(views: [NSView]) {
        for view in views {
            gestureHandlers.removeValue(forKey: view)
        }
    }

    func handle(_ touch: Touch) {
        convertToResponder(touch)

        switch touch.state {
        case .down:
            handleTouchDown(touch)
        case .up, .moved:
            if let handler = handler(for: touch) {
                handler.handle(touch)
            }
        }
    }

    func view(for gesture: GestureRecognizer) -> NSView? {
        for (view, handler) in gestureHandlers {
            if handler.owns(gesture) {
                return view
            }
        }

        return nil
    }


    // MARK: Helpers

    /// Displays a touch indicator at the touch position and produces a view if it exists at the location with interaction enabled.
    private func handleTouchDown(_ touch: Touch) {
        displayTouchIndicator(at: touch.position)

        if let view = target(in: responder.view, at: touch.position), let handler = gestureHandlers[view] {
            handler.handle(touch)
        }
    }

    /// Returns a handler from the gestures dictionary if it exists for the given view
    private func handler(for touch: Touch) -> GestureHandler? {
        guard let handler = gestureHandlers.values.first(where: { $0.owns(touch) }) else {
            return nil
        }

        return handler
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
        let radius = Constants.indicatorRadius
        let frame = CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: 2*radius, height: 2*radius))
        let touchIndicator = NSView(frame: frame)
        touchIndicator.wantsLayer = true
        touchIndicator.layer?.cornerRadius = radius
        touchIndicator.layer?.masksToBounds = true
        touchIndicator.layer?.borderWidth = radius / 4
        touchIndicator.layer?.borderColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 0.802921661)
        responder.view.addSubview(touchIndicator)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            touchIndicator.animator().alphaValue = 0.0
        }, completionHandler: {
            touchIndicator.removeFromSuperview()
        })
    }

    /// Returns the deepest possible view for the given point that is registered with a gesture handler.
    private func target(in view: NSView, at point: CGPoint) -> NSView? {
        guard view.frame.contains(point) else {
            return nil
        }

        let positionInBounds = transform(point, from: view)
        for subview in view.subviews.reversed() {
            if let target = target(in: subview, at: positionInBounds) {
                return target
            }
        }

        return gestureHandlers.keys.contains(view) ? view : nil
    }

    /// Transforms a point into the bounds of a given view.
    private func transform(_ point: CGPoint, from parent: NSView) -> NSPoint {
        return CGPoint(x: point.x - parent.frame.origin.x, y: point.y - parent.frame.origin.y)
    }
}
