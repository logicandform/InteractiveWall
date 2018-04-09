//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


protocol GestureResponder: class {
    var view: NSView { get }
    var gestureManager: GestureManager! { get }
}


final class GestureManager {

    private weak var responder: GestureResponder!
    private var gestureHandlers = [NSView: GestureHandler]()

    private struct Constants {
        static let indicatorRadius: CGFloat = 4
        static let indicatorDuration: Double = 0.6
    }

    var path: NSBezierPath?

    // MARK: Init

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
        switch touch.state {
        case .down:
            handleTouchDown(touch)
        case .moved:
            if let handler = handler(for: touch) {
                handler.handle(touch)
                displayTouchIndicator(in: responder.view, at: touch.position)
            }
        case .up:
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

    func owns(_ touch: Touch) -> Bool {
        return handler(for: touch) == nil ? false : true
    }


    // MARK: Helpers

    /// Displays a touch indicator at the touch position and produces a view if it exists at the location with interaction enabled.
    private func handleTouchDown(_ touch: Touch) {
        guard let window = responder.view.window else {
            return
        }

        displayTouchIndicator(in: responder.view, at: touch.position)

        if let (view, transform) = target(in: responder.view, at: touch.position, current: .identity, flipped: responder.view.isFlipped), let handler = gestureHandlers[view] {
            handler.set(transform, for: touch)
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


    /// Displays a touch indicator on the screen for testing
    private func displayTouchIndicator(in view: NSView, at position: CGPoint) {
        let radius = Constants.indicatorRadius
        let frame = CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: 2*radius, height: 2*radius))
        let touchIndicator = NSView(frame: frame)
        touchIndicator.wantsLayer = true
        touchIndicator.layer?.cornerRadius = radius
        touchIndicator.layer?.masksToBounds = true
        touchIndicator.layer?.backgroundColor = style.selectedColor.cgColor
        view.addSubview(touchIndicator)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.indicatorDuration
            touchIndicator.animator().alphaValue = 0.0
            touchIndicator.animator().frame.size = .zero
            touchIndicator.animator().frame.origin = CGPoint(x: touchIndicator.frame.origin.x + radius, y: touchIndicator.frame.origin.y + radius)
        }, completionHandler: {
            touchIndicator.removeFromSuperview()
        })
    }

    /// Returns the deepest possible view for the given point that is registered with a gesture handler along with the transform to that view.
    private func target(in view: NSView, at point: CGPoint, current: CGAffineTransform, flipped: Bool) -> (NSView, CGAffineTransform)? {
        guard view.frame.contains(point) else {
            return nil
        }

        var transform = current.translatedBy(x: -view.frame.minX, y: -view.frame.minY)
        var positionInBounds = point.transformed(to: view)

        // if coordinate geometry changes, convert point within frame
        if view.isFlipped != flipped {
            let yPos = view.frame.height - positionInBounds.y
            let yDiff = positionInBounds.y - yPos
            positionInBounds = CGPoint(x: positionInBounds.x, y: yPos)
            transform = transform.translatedBy(x: 0, y: -yDiff)
        }

        for subview in view.subviews.reversed() {
            if let target = target(in: subview, at: positionInBounds, current: transform, flipped: view.isFlipped) {
                return target
            }
        }

        let viewCanRespond = gestureHandlers.keys.contains(view) && !view.isHidden
        return viewCanRespond ? (view, transform) : nil
    }
}
