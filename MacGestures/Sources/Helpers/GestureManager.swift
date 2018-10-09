//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


public protocol GestureResponder: class {
    var view: NSView { get }
    var gestureManager: GestureManager! { get }
    func draggableInside(bounds: CGRect) -> Bool
    func subview(contains position: CGPoint) -> Bool
}


final public class GestureManager {
    public static let refreshRate = 1.0 / 60.0

    public var touchReceived: ((Touch) -> Void)?
    public weak var responder: GestureResponder!
    private var gestureHandlers = [NSView: GestureHandler]()


    // MARK: Init

    public init(responder: GestureResponder) {
        self.responder = responder
    }


    // MARK: API

    public func add(_ gesture: GestureRecognizer, to view: NSView) {
        guard let handler = gestureHandlers[view] else {
            gestureHandlers[view] = GestureHandler(gestures: [gesture])
            return
        }

        handler.add(gesture)
    }

    public func remove(views: [NSView]) {
        for view in views {
            gestureHandlers.removeValue(forKey: view)
        }
    }

    public func removeAll() {
        gestureHandlers.removeAll()
    }

    public func handle(_ touch: Touch) {
        touchReceived?(touch)

        switch touch.state {
        case .down:
            handleTouchDown(touch)
        case .moved, .up:
            if let handler = handler(for: touch) {
                handler.handle(touch)
            }
        }
    }

    /// If multiple views registered with the same gestrue, return value is undefined.
    public func view(for gesture: GestureRecognizer) -> NSView? {
        for (view, handler) in gestureHandlers {
            if handler.owns(gesture) {
                return view
            }
        }

        return nil
    }

    public func owns(_ touch: Touch) -> Bool {
        return handler(for: touch) == nil ? false : true
    }

    public func isActive() -> Bool {
        return gestureHandlers.values.contains(where: { !$0.touches.isEmpty })
    }

    public func invalidateAllGestures() {
        gestureHandlers.values.forEach { $0.gestures.forEach { $0.invalidate() } }
    }


    // MARK: Helpers

    /// Displays a touch indicator at the touch position and produces a view if it exists at the location with interaction enabled.
    private func handleTouchDown(_ touch: Touch) {
        guard let window = responder.view.window else {
            return
        }

        let windowTransform = CGAffineTransform(translationX: -window.frame.minX, y: -window.frame.minY)
        let positionInWindow = touch.position.applying(windowTransform)

        if let (view, transform) = target(in: responder.view, at: positionInWindow, current: windowTransform, flipped: responder.view.isFlipped), let handler = gestureHandlers[view] {
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
