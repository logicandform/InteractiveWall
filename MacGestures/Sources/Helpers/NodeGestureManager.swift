//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import SpriteKit


public protocol NodeGestureResponder: class {
    var view: NSView { get }
    var gestureManager: NodeGestureManager! { get }
}


final public class NodeGestureManager {

    public var touchReceived: ((Touch) -> Void)?
    public weak var responder: NodeGestureResponder!
    private var gestureHandlers = [SKNode: GestureHandler]()


    // MARK: Init

    public init(responder: NodeGestureResponder) {
        self.responder = responder
    }


    // MARK: API

    public func add(_ gesture: GestureRecognizer, to node: SKNode) {
        guard let handler = gestureHandlers[node] else {
            gestureHandlers[node] = GestureHandler(gestures: [gesture])
            return
        }

        handler.add(gesture)
    }

    public func remove(_ node: SKNode) {
        gestureHandlers.removeValue(forKey: node)
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

    public func node(for gesture: GestureRecognizer) -> SKNode? {
        for (node, handler) in gestureHandlers {
            if handler.owns(gesture) {
                return node
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
        gestureHandlers.values.forEach({ $0.gestures.forEach({ $0.invalidate() }) })
    }


    // MARK: Helpers

    private func handleTouchDown(_ touch: Touch) {
        guard let window = responder.view.window else {
            return
        }

        let windowTransform = CGAffineTransform(translationX: -window.frame.minX, y: -window.frame.minY)
        let positionInWindow = touch.position.applying(windowTransform)

        if let (node, transform) = target(in: responder.view, at: positionInWindow, current: windowTransform, flipped: responder.view.isFlipped), let handler = gestureHandlers[node] {
            handler.set(transform, for: touch)
            handler.handle(touch)
        }
    }

    private func handler(for touch: Touch) -> GestureHandler? {
        guard let handler = gestureHandlers.values.first(where: { $0.owns(touch) }) else {
            return nil
        }

        return handler
    }

    private func target(in view: NSView, at point: CGPoint, current: CGAffineTransform, flipped: Bool) -> (SKNode, CGAffineTransform)? {
        guard let skView = view as? SKView, skView.frame.contains(point), let scene = skView.scene else {
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

        guard let node = scene.nodes(at: point).first, gestureHandlers.keys.contains(node) else {
            return nil
        }

        return (node, transform)
    }
}
