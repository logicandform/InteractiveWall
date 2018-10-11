//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import MacGestures


class BaseViewController: NSViewController, GestureResponder {

    @IBOutlet weak var windowDragArea: NSView!
    @IBOutlet weak var dismissButton: NSView!
    @IBOutlet weak var windowDragAreaHighlight: NSView!
    @IBOutlet weak var titleLabel: NSTextField!

    var gestureManager: GestureManager!
    var type: WindowType!
    var animating = false
    var windowPanGesture: PanGestureRecognizer!
    var relationshipHelper: RelationshipHelper?
    weak var parentDelegate: RelationshipDelegate?
    weak var closeWindowTimer: Foundation.Timer?

    private struct Constants {
        static let animationDuration = 0.5
    }


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        gestureManager.touchReceived = { [weak self] touch in
            self?.receivedTouch(touch)
        }

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
        windowPanGesture.gestureUpdated = { [weak self] gesture in
            self?.handleWindowPan(gesture)
        }

        let singleFingerCloseButtonTap = TapGestureRecognizer()
        gestureManager.add(singleFingerCloseButtonTap, to: dismissButton)
        singleFingerCloseButtonTap.gestureUpdated = { [weak self] gesture in
            self?.didTapCloseButton(gesture)
        }
    }

    private func setupWindowDragArea() {
        windowDragArea.wantsLayer = true
        windowDragArea.layer?.backgroundColor = style.dragAreaBackground.cgColor
        windowDragAreaHighlight.wantsLayer = true
        windowDragAreaHighlight.layer?.backgroundColor = CGColor.white
    }


    // MARK: API

    func close() {
        parentDelegate?.controllerDidClose(self)
        WindowManager.instance.closeWindow(for: self)
    }

    func resetCloseWindowTimer() {
        guard WindowManager.instance.mode == .timeout else {
            return
        }

        closeWindowTimer?.invalidate()
        closeWindowTimer = Timer.scheduledTimer(withTimeInterval: Configuration.closeWindowTimeoutDuration, repeats: false) { [weak self] _ in
            self?.closeWindowTimerFired()
        }
    }

    func closeWindowTimerFired() {
        guard WindowManager.instance.mode == .timeout else {
            return
        }

        if let relationshipHelper = relationshipHelper {
            if relationshipHelper.isEmpty() {
                animateViewOut()
            }
        } else {
            animateViewOut()
        }
    }

    /// Animates `self` with all current child controllers to the given origin. Duration will depend on distance
    func setWindow(origin: CGPoint, animate: Bool, completion: (() -> Void)? = nil) {
        guard let window = view.window, let screen = window.screen else {
            return
        }

        let frame = CGRect(origin: origin, size: window.frame.size)
        let offset = abs(window.frame.minX - origin.x) / screen.frame.width
        let duration = max(Double(offset), Constants.animationDuration)

        setWindow(frame: frame, animate: animate, duration: duration, completion: completion)
    }

    /// Sets the frame of the window and updates all child controllers currently attached
    func setWindow(frame: CGRect, animate: Bool, duration: TimeInterval = Constants.animationDuration, completion: (() -> Void)? = nil) {
        guard let window = view.window else {
            return
        }

        animating = true
        gestureManager.invalidateAllGestures()
        resetCloseWindowTimer()
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            window.animator().setFrame(frame, display: true, animate: animate)
            self?.relationshipHelper?.updateChildPositionsFrom(frame: frame, animate: animate)
            }, completionHandler: { [weak self] in
                if let strongSelf = self {
                    strongSelf.animating = false
                    WindowManager.instance.checkBounds(of: strongSelf)
                }
                completion?()
        })
    }

    /// Updates the position of `self` along with all its child controllers based of its position in parent relationship
    func updateFromParent(frame: CGRect, animate: Bool) {
        guard let index = parentDelegate?.index(of: self) else {
            return
        }

        let offsetX = CGFloat(index) * style.windowStackOffset.dx
        let offsetY = CGFloat(index) * style.windowStackOffset.dy
        let lastScreen = NSScreen.at(position: Configuration.numberOfScreens)
        var origin = CGPoint(x: frame.maxX + style.windowMargins + offsetX, y: frame.maxY + offsetY - view.frame.height)

        if origin.x > lastScreen.frame.maxX - view.frame.width {
            if lastScreen.frame.height - frame.maxY < view.frame.height + style.windowMargins - 2 * offsetY {
                origin = CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y - frame.height - style.windowMargins)
            } else {
                origin = CGPoint(x: lastScreen.frame.maxX - view.frame.width - style.windowMargins, y: origin.y + view.frame.height + style.windowMargins - 2 * offsetY)
            }
        }

        setWindow(origin: origin, animate: animate)
    }

    func animateViewIn() {
        view.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            self?.view.animator().alphaValue = 1
        })
    }

    func animateViewOut() {
        NSAnimationContext.runAnimationGroup({ [weak self] _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            self?.view.animator().alphaValue = 0
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
            parentDelegate?.controllerDidMove(self)
            relationshipHelper?.reset()
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

        var origin = window.frame.origin
        origin += gesture.translation(in: nil)
        window.setFrameOrigin(origin)
        resetCloseWindowTimer()
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

    func subview(contains position: CGPoint) -> Bool {
        return view.subviews.contains(where: { $0.frame.contains(position) })
    }


    // MARK: Helpers

    private func receivedTouch(_ touch: Touch) {
        switch touch.state {
        case .down, .up:
            resetCloseWindowTimer()
            if windowPanGesture.state == .momentum {
                windowPanGesture.invalidate()
                WindowManager.instance.checkBounds(of: self)
            }
        case .moved:
            return
        }
    }
}
