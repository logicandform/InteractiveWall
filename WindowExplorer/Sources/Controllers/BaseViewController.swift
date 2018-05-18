//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class BaseViewController: NSViewController, GestureResponder {

    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var titleLabel: NSTextField!

    var gestureManager: GestureManager!
    var type: WindowType!
    var animating = false
    var windowPanGesture: PanGestureRecognizer!
    weak var parentDelegate: RelationshipDelegate?
    weak var closeWindowTimer: Foundation.Timer?

    private struct Constants {
        static let closeWindowTimeoutPeriod: TimeInterval = 300
        static let animationDuration = 0.5
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = receivedTouch(_:)

        setupGestures()
        setupWindowDragArea()
        resetCloseWindowTimer()
    }


    // MARK: Setup

    private func setupGestures() {
        let mousePan = NSPanGestureRecognizer(target: self, action: #selector(handleMousePan(_:)))
        windowDragArea.addGestureRecognizer(mousePan)

        windowPanGesture = PanGestureRecognizer()
        gestureManager.add(windowPanGesture, to: windowDragArea)
        windowPanGesture.gestureUpdated = handleWindowPan(_:)

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = didTapCloseButton(_:)
    }

    private func setupWindowDragArea() {
        windowDragArea.wantsLayer = true
        windowDragArea.layer?.backgroundColor = style.dragAreaBackground.cgColor
        windowDragAreaHighlight.wantsLayer = true
        windowDragAreaHighlight.layer?.backgroundColor = style.selectedColor.cgColor
    }


    // MARK: API

    func close() {
        WindowManager.instance.closeWindow(for: self)
    }

    func resetCloseWindowTimer() {
        closeWindowTimer?.invalidate()
        closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Constants.closeWindowTimeoutPeriod, repeats: false) { [weak self] _ in
            self?.animateViewOut()
        }
    }

    func animate(to origin: NSPoint) {
        guard let window = view.window, let screen = window.screen, !gestureManager.isActive() else {
            return
        }

        gestureManager.invalidateAllGestures()
        resetCloseWindowTimer()
        animating = true
        window.makeKeyAndOrderFront(self)

        let frame = CGRect(origin: origin, size: window.frame.size)
        let offset = abs(window.frame.minX - origin.x) / screen.frame.width
        let duration = max(Double(offset), Constants.animationDuration)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = duration
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            window.animator().setFrame(frame, display: true, animate: true)
        }, completionHandler: { [weak self] in
            self?.animating = false
        })
    }

    func updatePosition(animating: Bool) {
        // Override
    }

    func animateViewIn() {
        view.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = 1
        })
    }

    func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.close()
        })
    }


    // MARK: Gesture Handling

    func handleWindowPan(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer, let window = view.window, !animating else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            var origin = window.frame.origin
            origin += pan.delta.round()
            window.setFrameOrigin(origin)
        case .possible:
            WindowManager.instance.checkBounds(of: self)
        default:
            return
        }
    }

    func didTapCloseButton(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, tap.state == .ended, !animating else {
            return
        }

        animateViewOut()
    }

    @objc
    private func handleMousePan(_ gesture: NSPanGestureRecognizer) {
        guard let window = view.window, !animating else {
            return
        }

        resetCloseWindowTimer()
        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
    }


    // MARK: GestureResponder

    /// Determines if the bounds of the draggable area is inside a given rect
    func draggableInside(bounds: CGRect) -> Bool {
        guard let window = view.window else {
            return false
        }

        // Calculate the center box of the drag area in the window's coordinate system
        let dragAreaInWindow = windowDragArea.frame.transformed(from: view.frame).transformed(from: window.frame)
        let adjustedWidth = dragAreaInWindow.width / 2
        let smallDragArea = CGRect(x: dragAreaInWindow.minX + adjustedWidth / 2, y: dragAreaInWindow.minY, width: adjustedWidth, height: dragAreaInWindow.height)
        return bounds.contains(smallDragArea)
    }

    func contains(position: CGPoint) -> Bool {
        return view.subviews.first(where: { $0.frame.contains(position) }) != nil
    }


    // MARK: Helpers

    private func receivedTouch(_ touch: Touch) {
        switch touch.state {
        case .down, .up:
            resetCloseWindowTimer()
            if windowPanGesture.state == .momentum {
                windowPanGesture.invalidate()
            }
        case .moved, .indicator:
            return
        }
    }
}
