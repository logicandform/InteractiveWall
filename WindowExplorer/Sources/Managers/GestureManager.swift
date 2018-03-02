//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MapKit


protocol GestureResponder: class {
    var view: NSView { get }
    var gestureManager: GestureManager! { get }
}


final class GestureManager {

    private weak var responder: GestureResponder!
    private var gestureHandlers = [NSView: GestureHandler]()

    private struct Constants {
        static let indicatorRadius: CGFloat = 10
    }


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

    func removeAll() {
        gestureHandlers.removeAll()
    }

    func handle(_ touch: Touch) {
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

    func owns(_ touch: Touch) -> Bool {
        return handler(for: touch) == nil ? false : true
    }


    // MARK: Helpers

    /// Displays a touch indicator at the touch position and produces a view if it exists at the location with interaction enabled.
    private func handleTouchDown(_ touch: Touch) {
        guard let screen = NSScreen.screens.at(index: touch.screen), let window = responder.view.window else {
            return
        }
        
        let windowTransform = CGAffineTransform(translationX: -window.frame.minX, y: -window.frame.minY)
        let positionInWindow = touch.position.applying(windowTransform)
        displayTouchIndicator(in: responder.view, at: positionInWindow)

        if let (view, transform) = target(in: responder.view, at: positionInWindow, current: windowTransform), let handler = gestureHandlers[view] {
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
        touchIndicator.layer?.borderWidth = radius / 4
        touchIndicator.layer?.borderColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        view.addSubview(touchIndicator)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = 1.0
            touchIndicator.animator().alphaValue = 0.0
        }, completionHandler: {
            touchIndicator.removeFromSuperview()
        })
    }

    /// Returns the deepest possible view for the given point that is registered with a gesture handler along with the transform to that view.
    private func target(in view: NSView, at point: CGPoint, current: CGAffineTransform) -> (NSView, CGAffineTransform)? {
        guard view.frame.contains(point) else {
            return nil
        }

        let transform = current.translatedBy(x: -view.frame.origin.x, y: -view.frame.origin.y)
        let positionInBounds = point.transformed(to: view)
        for subview in view.subviews.reversed() {
            if let target = target(in: subview, at: positionInBounds, current: transform) {
                return target
            }
        }

        return gestureHandlers.keys.contains(view) ? (view, transform) : nil
    }
}
